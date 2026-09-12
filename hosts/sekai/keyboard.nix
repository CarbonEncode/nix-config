{ pkgs, ... }:
{
  # The Azoth receiver can report a malformed serial at cold boot. Power-cycle its USB port
  # after unlocking, before GDM opens the input devices. This is a
  # workaround for https://github.com/systemd/systemd/issues/41296, not a
  # systemd/kernel override. Keep it outside generated hardware configuration.
  systemd.services.azoth-reconnect = {
    description = "Reconnect ROG Azoth receiver before the login screen";
    wantedBy = [ "display-manager.service" ];
    before = [ "display-manager.service" ];
    after = [ "systemd-udev-trigger.service" "plymouth-quit.service" ];
    path = [ pkgs.coreutils pkgs.systemd pkgs.uhubctl pkgs.gnugrep ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 45;
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
      device=
      for candidate in /sys/bus/usb/devices/*; do
        [ -r "$candidate/idVendor" ] && [ -r "$candidate/idProduct" ] || continue
        [ "$(cat "$candidate/idVendor")" = "0b05" ] || continue
        [ "$(cat "$candidate/idProduct")" = "1a85" ] || continue
        if [ -n "$device" ]; then
          echo "Multiple Azoth receivers found; refusing an ambiguous power cycle" >&2
          exit 1
        fi
        device=$candidate
      done
      if [ -z "$device" ]; then
        echo "No Azoth receiver connected; skipping"
        exit 0
      fi
      address=$(basename "$device")
      case "$address" in
        *.*)
          hub=''${address%.*}
          port=''${address##*.}
          ;;
        *)
          # Directly attached to a root hub: uhubctl uses the bus number.
          hub=''${address%%-*}
          port=''${address##*-}
          ;;
      esac
      echo "Power-cycling Azoth at $address (hub $hub, port $port)"
      # uhubctl checks hub power-switching support and handles the USB3
      # companion automatically. Do not use --force or cycle the parent hub.
      uhubctl -l "$hub" -p "$port"
      restore_power() {
        uhubctl -l "$hub" -p "$port" -a on
      }
      trap restore_power EXIT
      uhubctl -l "$hub" -p "$port" -a off
      sleep 3
      restore_power
      trap - EXIT
      # Wait for actual enumeration, not merely an empty udev queue.
      ready=false
      for attempt in $(seq 1 10); do
        if [ -r "$device/serial" ] &&
           [ "$(cat "$device/idVendor")" = "0b05" ] &&
           [ "$(cat "$device/idProduct")" = "1a85" ] &&
           LC_ALL=C grep -qx '[[:alnum:]]\+' "$device/serial"; then
          ready=true
          break
        fi
        sleep 1
      done
      if [ "$ready" != true ]; then
        echo "Azoth did not return with a clean serial; power-cycle workaround failed" >&2
        exit 1
      fi
      udevadm settle --timeout=10
      echo "Azoth re-enumerated with a clean serial"
      touch /run/azoth-reconnect-done
    '';
  };
}
