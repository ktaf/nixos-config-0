{ config, pkgs, lib, ... }:

let
  hostAddress = "10.100.0.1";
  localAddress = "10.100.0.2";
in {
  services.nginx.enable = true;
  services.nginx.recommendedProxySettings = true;

  services.nginx.virtualHosts."nextcloud.fullmer.me".locations."/".proxyPass = "http://10.100.0.2/";
  networking.nat.enable = true;
  networking.nat.internalIPs = [ localAddress ];
  services.unbound.settings.server.interface = [ hostAddress ];
  services.unbound.settings.server.access-control = [ "10.100.0.0/24 allow" ];
  networking.firewall.interfaces."ve-nextcloud".allowedUDPPorts = [ 53 ];
  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    config = { config, pkgs, ... }:
    {
      networking.hosts = {
        "${hostAddress}" = [ "office.daniel.fullmer.me" ];
      };
      networking.nameservers = [ "10.100.0.1" ];
      networking.useHostResolvConf = false;
      services.resolved.enable = true;

      services.nextcloud = {
        enable = true;
        hostName = "nextcloud.fullmer.me";
        autoUpdateApps.enable = true;
        config = {
          dbtype = "sqlite";
          # dbtype = "pgsql"; # TODO: Convert to postgres?
          #dbuser = "nextcloud";
          #dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
          #dbname = "nextcloud";
          adminpassFile = "/var/secrets/nextcloud";
          adminuser = "root";
        };
        settings = {
          trusted_domains = [ localAddress ]; # Ensure the "proxyPass" location is a valid domain
          overwriteprotocol = "https"; # Since we're behind nginx reverse proxy, we need to know that we should always use https
        };
      };

      services.postgresql = {
        #enable = true;
        initialScript = pkgs.writeText "psql-init" ''
          CREATE ROLE nextcloud WITH LOGIN;
          CREATE DATABASE nextcloud WITH OWNER nextcloud;
        '';
      };

#      systemd.services.local-dns-tunnel = {
#        script = ''
#          ${pkgs.socat}/bin/socat UDP4-LISTEN:53,reuseaddr,fork UDP4-CONNECT:10.100.0.1:53
#        '';
#        wantedBy = [ "multi-user.target" ];
#      };

      # ensure that postgres is running *before* running the setup
      #systemd.services."nextcloud-setup" = {
      #  requires = ["postgresql.service"];
      #  after = ["postgresql.service"];
      #};

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      environment.systemPackages = with pkgs; [ ffmpeg imagemagick ghostscript ];
    };
  };

#  virtualisation.oci-containers.onlyoffice = {
#    image = "onlyoffice/documentserver";
#    ports = [ "9980:80" ];
#    extraDockerOptions = [ "--add-host=office.daniel.fullmer.me:30.0.0.222" ];
#  };

  # https://www.collaboraoffice.com/code/docker/ for instructions
#  docker-containers.code = {
#    image = "collabora/code";
#    ports = [ "9980:9980" ];
#    environment = {
#      domain = "nextcloud\\.fullmer\\.me";
#    };
#    extraDockerOptions = [
#      "--cap-add=MKNOD"
#      "--add-host=office.daniel.fullmer.me:30.0.0.222"
#    ];
#  };
  services.nginx.virtualHosts."office.daniel.fullmer.me" = {
    locations."/" = {
      proxyPass = "https://[::1]:9980";
      # proxyPass = "http://[::1]:9980/"; # For onlyoffice
      proxyWebsockets = true;
#      extraConfig = ''
#        proxy_set_header Host $http_host;
#        proxy_read_timeout 3600
#      '';
    };
  };
}
