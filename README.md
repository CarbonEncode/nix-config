# NixOS configuration

Shared system modules with per-machine configuration. The only registered machine is currently `sekai`: Intel Core i5-14600KF, Intel Arc B580, and Wi-Fi networking.

GNOME with GDM provides the desktop and login screen. NetworkManager manages Wi-Fi through GNOME Settings. PipeWire handles audio; GNOME provides keyring, Bluetooth, power settings, and removable-drive integration. Plymouth provides the graphical boot and encrypted-disk password prompt. Printing is disabled. Desktop applications include Vivaldi with `vivaldi-ffmpeg-codecs`, Vesktop (Vencord), Deezer Desktop (the unofficial aunetx Linux port), Proton Pass, Steam, VSCodium, VLC, MPV, Files, Console, Text Editor, an image viewer, a PDF viewer, Archive Manager, Disks, and Passwords and Keys. Vivaldi is the default browser; Firefox is not installed. Dash to Dock, Blur my Shell, Apps Menu, and Extension Manager are included. Shared command-line tools include `dig`, `host`, `nslookup`, `mtr`, Ansible, OpenSSH (`ssh`, `scp`, `sftp`, `ssh-keygen`), Git, curl, wget, jq, rsync, traceroute, tcpdump, iproute2 (`ip`, `ss`), fastfetch, btop, smartmontools (`smartctl`), lm_sensors (`sensors`), usbutils (`lsusb`), pciutils (`lspci`), unzip, and ncdu. The SSH client is installed; incoming SSH access is not enabled.

GNOME defaults to the bundled wallpaper, dark appearance, and minimize/maximize/close window buttons. These defaults remain editable by each user in GNOME Settings or dconf.

GNOME Shell includes the recommended screenshot and screen-recording tool even
with the minimal core-app selection. Press **Print Screen** to capture a region,
window, or screen; switch to video mode to record a region or screen. Screenshots
are saved in `~/Pictures/Screenshots`, and recordings in `~/Videos/Screencasts`.
See the [GNOME capture guide](https://help.gnome.org/gnome-help/screen-shot-record.html).

The configuration uses a recent Linux kernel, Mesa, Intel media support and redistributable firmware. The exact Wi-Fi adapter was not specified; adapters requiring drivers outside the kernel may need additional configuration. Connect the monitor to the B580: the KF CPU has no integrated graphics.

## Disk layout

UEFI boot is required. Installation erases the selected whole disk.

| Layer | Layout |
| --- | --- |
| GPT partition 1 | 2048 MiB FAT32 EFI system partition mounted at `/boot` |
| GPT partition 2 | Remaining space, password-unlocked LUKS mapping `cryptlvm` |
| Inside LUKS | LVM volume group `vg00` |
| Inside LVM | 200 GiB ext4 logical volume `root`, mounted at `/` |
| Inside LVM | Ext4 logical volume `home`, using all remaining space, mounted at `/home` |

The 2048 MiB EFI size applies to fresh partitioning. A normal rebuild does not resize an existing `/boot`; do not rerun the destructive installer to apply this change.

The logical volumes are `/dev/vg00/root` and `/dev/vg00/home`. The target disk must have enough usable encrypted space for the 200 GiB root volume. These sizes and the separate home filesystem apply to fresh partitioning; a normal rebuild does not resize or create them.

`/nix` lives on the root filesystem, while `/home` has its own logical volume inside the same encrypted container. The EFI partition is unencrypted. There is no TPM unlocking, keyfile, disk swap, or hibernation setup. Compressed RAM swap (zram) is enabled.

Disk swap is explicitly disabled, and Bluetooth is enabled and powered on at boot. PipeWire with WirePlumber manages audio, including Bluetooth audio devices paired through GNOME Settings. TPM support is disabled; unlocking the encrypted disk requires your passphrase each time.

Networking uses the `fq` queueing discipline with BBR TCP congestion control on every configured host.

## Install

1. Boot a recent **x86_64 NixOS graphical ISO in UEFI mode**. Disable Secure Boot; this configuration uses ordinary systemd-boot without Secure Boot enrollment.
2. Connect Wi-Fi using the live desktop. Copy this project to a writable directory on the live system, such as `/tmp/nix-config`, and open a terminal there.
3. Review `hosts/sekai/settings.nix`. The login name is `prime`; defaults are Stockholm time, US English (`en_US.UTF-8`), and a Swedish keyboard. Set the live environment keyboard to match before entering passwords.
4. Run:

   ```bash
   ./install.sh sekai
   ```

The installer accepts an optional hostname (default `sekai`), uses the login name from that host’s settings (`prime` for `sekai`), and asks for the target disk. It builds the system and locked Disko tool before requiring you to retype the disk path to authorize erasing it. The initial build can take some time; downloaded and built packages are reused during installation. It prompts for the disk passphrase, generates the actual hardware configuration, installs NixOS, and prompts for root and user passwords. No secrets are written to this project.

After reboot, unlock the disk with its passphrase and log in through GDM. Reconnect Wi-Fi in GNOME Settings. Wi-Fi passwords from the live ISO are not copied into the installed system.

If installation fails after formatting, do not rerun the destructive installer. With the target still mounted at `/mnt` and configuration already copied, resume using:

```bash
sudo nixos-install --root /mnt --flake path:/mnt/etc/nixos#sekai
sudo nixos-enter --root /mnt -c 'passwd YOUR_LOGIN_NAME'
```

If failure occurred before copying the configuration, finish the hardware-generation and copying steps in `install.sh` first.

## Maintain

The installer copies the flake, all host configurations, and shared modules to `/etc/nixos`. Edit it there and apply changes:

```bash
sudo nixos-rebuild switch --flake path:/etc/nixos#sekai
```

To intentionally update the pinned dependencies:

```bash
cd /etc/nixos
sudo nix flake update nixpkgs
sudo nixos-rebuild switch --flake path:/etc/nixos#sekai
```

Keep `system.stateVersion` at `26.05` after installation; it controls compatibility defaults and is not the package update channel.
The package channel is pinned to the `nixos-26.05` stable branch in `flake.nix`.
The installer refreshes that branch before building, and the configuration
refuses to evaluate against a different NixOS release.
When a newer stable release is published, update the branch in `flake.nix` and
the release assertion in `modules/global/system.nix`, refresh the lock, and
validate the configuration before upgrading. Never select an unstable branch.
Keep the existing machine's `system.stateVersion` unchanged during upgrades.

The stable migration's lock file still needs regeneration on a machine with Nix:

```bash
nix flake update nixpkgs
nix flake check --no-build --all-systems
```

Commit the regenerated `flake.lock` after a successful check. The installer also
refreshes the lock before building, but the repository lock must be updated to
make the stable migration fully pinned and validated.

## Shared packages and GNOME extensions

Edit `modules/desktop/apps.nix` for shared desktop applications. This module permits the unfree packages required by Vivaldi and Steam. Steam’s NixOS integration enables 32-bit graphics and audio compatibility; PipeWire with WirePlumber remains the audio server. Vivaldi’s codec package is integrated through its `proprietaryCodecs` override.

Add command-line packages to `environment.systemPackages` in `modules/global/packages.nix`. Every host registered through `mkHost` automatically imports this module. Mtr uses `programs.mtr.enable` in the same file so its network-probing permissions are configured properly.

Add GNOME extensions to the `extensions` list in `modules/desktop/extensions.nix`, using package names from `pkgs.gnomeExtensions`. The list supplies both installed packages and extension IDs enabled by default. Dash to Dock, Blur my Shell, and Apps Menu are installed and enabled by default. Extensions must support the GNOME version in the pinned Nixpkgs release.

These are editable system defaults. Open **Extension Manager** to enable, disable, or configure extensions. Existing per-user choices take precedence over new defaults; after adding an extension and rebuilding, log out and back in and enable it in Extension Manager if needed.

## Add another device

1. Create `hosts/<name>/` with `default.nix`, `settings.nix`, `disk.nix`, and `hardware-configuration.nix`. Use `sekai` as a structure reference, but replace its Intel graphics/CPU settings, disk selection, and hardware configuration with those appropriate to the new machine. Set that machine’s initial `system.stateVersion` in its `default.nix`.
2. Keep the settings fields `username`, `diskDevice`, `timeZone`, `locale`, and `keyboardLayout`. `mkHost` passes these to the shared system module.
3. Import `../../modules/desktop/gnome.nix` in the new host’s `default.nix` if it should use this desktop. Import its local disk and hardware files as well. Hardware and disk layouts stay per host.
4. Add `<name> = mkHost "<name>";` under `nixosConfigurations` in `flake.nix`. The helper sets the hostname and imports all global modules. It currently targets x86_64 Linux; another architecture also needs an architecture-aware helper and installer.
5. On the new machine’s UEFI-booted NixOS ISO, run `./install.sh <name>`. It regenerates only the selected host’s hardware file. Disk layout and bootloader must be compatible with this UEFI installer.

For future rebuilds on that device, use `sudo nixos-rebuild switch --flake path:/etc/nixos#<name>`. Shared modules apply to each device when it is rebuilt; editing the project does not automatically deploy changes to other devices.

## Files

| File | Purpose |
| --- | --- |
| `flake.nix` / `flake.lock` | Host registration, shared imports, pinned dependencies |
| `modules/global/default.nix` | Entry point imported for every host |
| `modules/global/packages.nix` | Global command-line tools |
| `modules/global/system.nix` | NetworkManager, locale, user, zram, TPM policy |
| `modules/desktop/gnome.nix` | Optional GNOME/GDM profile, apps, PipeWire, Bluetooth |
| `modules/desktop/appearance.nix` | Wallpaper, dark appearance, and window-button defaults |
| `modules/desktop/assets/default-wallpaper.jpg` | Bundled default wallpaper |
| `modules/desktop/apps.nix` | Shared desktop apps, Vivaldi browser defaults, Steam integration |
| `modules/desktop/extensions.nix` | GNOME extensions and default enablement |
| `hosts/sekai/default.nix` | Desktop profile selection, Intel hardware, bootloader, Plymouth, state version |
| `hosts/sekai/settings.nix` | Disk, login name, locale, keyboard, timezone |
| `hosts/sekai/disk.nix` | EFI plus LVM inside LUKS with ext4 root and home volumes |
| `hosts/sekai/hardware-configuration.nix` | Generated on the target during installation |
| `install.sh` | Interactive installation of a selected host |

References: [NixOS GNOME documentation](https://nixos.org/manual/nixos/stable/#sec-gnome), [NixOS dconf module](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/dconf.nix), and [Disko LUKS/LVM example](https://github.com/nix-community/disko/blob/master/example/luks-lvm.nix).
