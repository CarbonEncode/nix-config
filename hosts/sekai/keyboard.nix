{ ... }:
{
  # Fix malformed Azoth serial properties at the device-event parser, including
  # the libraries used by desktop clients. systemdMinimal/systemdLibs inherit
  # this override from systemd in Nixpkgs. No USB reset service is needed.
  nixpkgs.overlays = [
    (_final: prev: {
      systemd = prev.systemd.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Upstream PR #43489, including its regression tests. Skip only when
          # the exact patch is already present in a future stable update.
          if patch --batch --dry-run --forward -p1 < ${./patches/systemd-ignore-invalid-properties.patch}; then
            patch --batch --forward -p1 < ${./patches/systemd-ignore-invalid-properties.patch}
          elif patch --batch --dry-run --reverse -p1 < ${./patches/systemd-ignore-invalid-properties.patch}; then
            echo "Upstream invalid-device-property fix already present"
          else
            echo "systemd device-property backport needs review for this source version" >&2
            exit 1
          fi
        '';
      });
    })
  ];
}
