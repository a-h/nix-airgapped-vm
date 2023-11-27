# system-manager module.
{ lib, pkgs, app, ... }:

{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";

    system-manager.allowAnyDistro = true;

    # System level dependencies can be added here.
    environment = {
      systemPackages = [
        #pkgs.ripgrep
        #pkgs.fd
        #pkgs.hello
      ];
    };

    systemd.services = {
      example-go-project = {
        enable = true;
        serviceConfig = {
          Type = "simple";
        };
        wantedBy = [ "system-manager.target" ];
        script = ''
          ${lib.getBin app}/bin/example-go-project
        '';
      };
    };
  };
}

