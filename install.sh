#!/usr/bin/env bash
# Run from a recent NixOS graphical ISO, booted in UEFI mode.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if (( $# > 1 )); then
  echo "Usage: $0 [hostname] (default: sekai)" >&2
  exit 1
fi
TARGET_HOST=${1:-sekai}
if [[ ! $TARGET_HOST =~ ^[a-z][a-z0-9-]*$ ]] || [[ ! -f hosts/$TARGET_HOST/default.nix || ! -f hosts/$TARGET_HOST/settings.nix ]]; then
  echo "Unknown host: $TARGET_HOST. Add its host files and flake entry first." >&2
  exit 1
fi
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
  echo "Run this on the target machine from an x86_64 NixOS installation ISO." >&2
  exit 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
  echo "Reboot the installation ISO in UEFI mode." >&2
  exit 1
fi
for command in nix nixos-install nixos-generate-config nixos-enter lsblk findmnt sudo sed; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"
FLAKE_REF="path:$PWD#$TARGET_HOST"
CONFIG_REF="path:$PWD#nixosConfigurations.$TARGET_HOST"
# Refresh only nixpkgs within the 26.05 stable branch before evaluating. This
# keeps new installations on current security and bug-fix revisions without
# ever advancing to the 26.11 development branch.
nix flake lock --update-input nixpkgs

# Verify the flake entry exists before asking for disk details.
nix eval --raw "$CONFIG_REF.config.networking.hostName" >/dev/null
INSTALL_USERNAME=$(nix eval --raw --file "hosts/$TARGET_HOST/settings.nix" username)
if [[ ! $INSTALL_USERNAME =~ ^[a-z][a-z0-9_-]{0,30}$ || $INSTALL_USERNAME == root || $INSTALL_USERNAME == nixbld* ]]; then
  echo "Set a normal lowercase login name in hosts/$TARGET_HOST/settings.nix (not root or nixbld)." >&2
  exit 1
fi
echo "Installing $TARGET_HOST with login name $INSTALL_USERNAME."

lsblk -o PATH,SIZE,MODEL,TYPE,MOUNTPOINTS
read -r -p "Whole disk to ERASE (prefer /dev/disk/by-id/...): " DISK_DEVICE
# Limit characters before putting this value in a Nix string.
if [[ ! $DISK_DEVICE =~ ^/dev/[a-zA-Z0-9_./:+-]+$ ]] || [[ ! -b $DISK_DEVICE ]]; then
  echo "Invalid block-device path." >&2
  exit 1
fi
if [[ $(lsblk -dnro TYPE "$DISK_DEVICE") != disk ]]; then
  echo "Choose a whole disk, not a partition or logical volume." >&2
  exit 1
fi
# Capture first so a failed lsblk cannot bypass the mounted-disk check.
DISK_MOUNTS=$(lsblk -nro MOUNTPOINTS "$DISK_DEVICE")
if [[ $DISK_MOUNTS =~ [^[:space:]] ]]; then
  echo "The disk has mounted filesystems or active swap. Unmount them before installing." >&2
  exit 1
fi
if findmnt -rn -R /mnt >/dev/null; then
  echo "/mnt already has mounts. Unmount them before installing." >&2
  exit 1
fi
# Only replace the selected disk; retain the configured account and locale.
sed -i -E \
  -e "s|^  diskDevice = .*|  diskDevice = \"$DISK_DEVICE\";|" \
  "hosts/$TARGET_HOST/settings.nix"

echo "Building $TARGET_HOST and the pinned partitioning tool before erasing anything..."
nix build --no-link "$CONFIG_REF.config.system.build.toplevel"
DISKO_OUTPUT=$(nix build --no-link --print-out-paths "path:$PWD#disko")

echo "ALL DATA ON $DISK_DEVICE WILL BE DESTROYED."
read -r -p "Type the full disk path again to confirm: " CONFIRM_DISK
if [[ $CONFIRM_DISK != "$DISK_DEVICE" ]]; then
  echo "Cancelled."
  exit 1
fi
echo "Set a disk passphrase when prompted; it will be required at every boot."
sudo env NIX_CONFIG="$NIX_CONFIG" "$DISKO_OUTPUT/bin/disko" \
  --mode disko --flake "$FLAKE_REF"

sudo nixos-generate-config --no-filesystems --root /mnt
sudo cat /mnt/etc/nixos/hardware-configuration.nix > "hosts/$TARGET_HOST/hardware-configuration.nix"

# Keep the actual configuration on the installed machine for future rebuilds.
sudo mkdir -p /mnt/etc/nixos
sudo cp flake.nix flake.lock README.md /mnt/etc/nixos/
sudo cp -R hosts modules /mnt/etc/nixos/
sudo nixos-install --root /mnt --flake "path:/mnt/etc/nixos#$TARGET_HOST"
sudo nixos-enter --root /mnt -c "passwd $INSTALL_USERNAME"

cat <<DONE
Installation complete. Reboot and remove the installation media.
Enter your disk passphrase at boot, then sign in through GDM.
Connect Wi-Fi through GNOME Settings; the live ISO connection is not copied.
Your configuration is in /etc/nixos. To apply future changes:
  sudo nixos-rebuild switch --flake path:/etc/nixos#$TARGET_HOST
DONE
