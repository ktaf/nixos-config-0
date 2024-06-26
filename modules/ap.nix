{ config, pkgs, lib, utils, ... }:

with lib;
let
  cfg = config.controlnet.ap;
in
{
  options = {
    controlnet.ap = {
      enable = mkEnableOption "access point";

      interface = mkOption {
        default = "wlan0";
        type = types.str;
      };

      subnetNumber = mkOption {
        type = types.int;
      };

      ssid = mkOption {
        default = "controlnet_nomap";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    services.hostapd = {
      enable = true;
#      inherit (cfg) interface ssid;
#      # For each device, they are going to have to add their own hwMode, extraConfig for ht_capab, what ieee modes are supported etc.
#      extraConfig = ''
#        wpa=2
#        wpa_psk_file=${config.sops.secrets.wpa_psk_file.path}
#        country_code=US
#        rsn_pairwise=CCMP
#        wpa_key_mgmt=WPA-PSK
#      '';
      radios.${cfg.interface}.networks.${cfg.interface} = {
        inherit (cfg) ssid;
        authentication = {
          mode = "wpa2-sha256";
          #mode = "wpa3-sae-transition"; # TODO: Switch to wpa3-sae entirely, remove WPA-PSK. 8sleep doesn't support WPA3
          wpaPskFile = config.sops.secrets.wpa_psk_file.path;
          saePasswordsFile = config.sops.secrets.sae_passwords.path;
        };

        settings.wpa_key_mgmt = lib.mkForce "WPA-PSK"; # TODO: 8sleep doesn't like WPA-PSK-SHA256. Put it on a different interface
      };
    };
    sops.secrets.wpa_psk_file = {
      format = "binary";
      sopsFile = ../secrets/wpa_psk_file;
    };
    sops.secrets.sae_passwords.sopsFile = ../secrets/secrets.yaml;

    # Sometimes, the device crashes and restarts, since hostapd has BindTo the
    # device, and we want hostapd to restart when the device comes back up, add
    # a WantedBy relationship here.
    systemd.services.hostapd.wantedBy = [ "sys-subsystem-net-device-${utils.escapeSystemdPath cfg.interface}.device" ];

    networking.interfaces."${cfg.interface}".ipv4.addresses = [ { address = "192.168.${toString cfg.subnetNumber}.1"; prefixLength = 24; }];
    networking.firewall.interfaces."${cfg.interface}" = {
      allowedUDPPorts = [ 53 67 ]; # DNS and DHCP
    };
    networking.nat.enable = true;
    networking.nat.internalInterfaces = [ cfg.interface ];

    services.dnsmasq = {
      enable = true;
      settings = {
        interface = cfg.interface;
        dhcp-range = "interface:${cfg.interface},192.168.${toString cfg.subnetNumber}.2,192.168.${toString cfg.subnetNumber}.254";
      };
    };

    hardware.wirelessRegulatoryDatabase = true;
    environment.systemPackages = with pkgs; [ wirelesstools iw ];
  };
}
