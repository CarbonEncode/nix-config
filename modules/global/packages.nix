# Add command-line tools here to make them available to all users on all hosts.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dnsutils # dig, host, nslookup
    ansible # ansible, ansible-playbook, ansible-galaxy
    openssh # ssh, scp, sftp, ssh-keygen
    git
    curl
    wget
    jq
    rsync
    traceroute
    tcpdump
    iproute2 # ip, ss
    fastfetch
    btop
    smartmontools # smartctl
    lm_sensors # sensors
    usbutils # lsusb
    pciutils # lspci
    unzip
    ncdu
  ];

  # Includes mtr and the permissions needed for unprivileged network probes.
  programs.mtr.enable = true;
}
