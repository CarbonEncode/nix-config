{ pkgs, ... }:
{
  # The Azoth receiver can report a malformed serial at cold boot. Reprobe its
  # interfaces after unlocking, before GDM opens the input devices. This is a
  # workaround for https://github.com/systemd/systemd/issues/41296, not a
  # systemd/kernel override. Keep it outside generated hardware configuration.
  systemd.services.azoth-reconnect = {
    description = "Reconnect ROG Azoth receiver before the login screen";
    wantedBy = [ "display-manager.service" ];
    before = [ "display-manager.service" ];
    after = [ "systemd-udev-trigger.service" "plymouth-quit.service" ];
    path = [ pkgs.coreutils pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
    };
    # Do not reconnect during nixos-rebuild switch in a running desktop.
    restartIfChanged = false;
    unitConfig.ConditionPathExists = "!/run/azoth-reconnect-done";
    script = ''
      if systemctl --quiet is-active display-manager.service; then
        echo "Desktop already running; reconnect deferred until next boot"
        exit 0
      fi
      udevadm settle --timeout=10
      for device in /sys/bus/usb/devices/*; do
        [ -r "$device/idVendor" ] && [ -r "$device/idProduct" ] || continue
        [ "$(cat "$device/idVendor")" = "0b05" ] || continue
        [ "$(cat "$device/idProduct")" = "1a85" ] || continue
        [ -w "$device/authorized" ] || continue
        echo "Reconnecting ROG Azoth receiver at $device"
        # Always restore authorization if interrupted during the reconnect.
        trap 'echo 1 > "$device/authorized"' EXIT
        echo 0 > "$device/authorized"
        sleep 1
        echo 1 > "$device/authorized"
        trap - EXIT
      done
      udevadm settle --timeout=10
      touch /run/azoth-reconnect-done
    '';
  };
}
