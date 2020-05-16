# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

with lib;
{
  nixpkgs.localSystem = { system = "aarch64-linux"; config = "aarch64-unknown-linux-gnu"; };

  boot.initrd.availableKernelModules = [ "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8812au ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 6;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  services.xserver.windowManager.i3.status = {
    config = ''
      battery 1 {
              format = "%status %percentage %remaining %emptytime"
              format_down = "No battery"
              status_chr = "⚡ CHR"
              status_bat = "🔋 BAT"
              status_full = "☻ FULL"
              path = "/sys/class/power_supply/BAT%d/uevent"
              low_threshold = 10
      }
    '';
    order = mkBefore [ "battery 1" ];
  };
}
