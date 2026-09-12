{ ... }:
let
  settings = import ./settings.nix;
in
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = settings.diskDevice;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # Disko prompts for a passphrase. No keyfile or TPM enrollment.
              passwordFile = null;
              askPassword = true;
              content = {
                type = "lvm_pv";
                vg = "sekai";
              };
            };
          };
        };
      };
    };
    lvm_vg.sekai = {
      type = "lvm_vg";
      lvs.root = {
        size = "100%FREE";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };
}
