{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xc = {
      url = "github:joerdav/xc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    example-go-project = {
      url = "path:./example-go-project";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, xc, deploy-rs, system-manager, example-go-project, ... }:
    let
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes.
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        system = system;
        pkgs = import nixpkgs { inherit system; };
      });

      # All of the required development tools.
      devTools = { system, pkgs }: [
        xc.packages.${system}.xc
        deploy-rs.packages.${system}.deploy-rs
        pkgs.lima
      ];

      config = system-manager.lib.makeSystemConfig
        {
          modules = [
            ./example-go-project-service.nix
          ];
          # These arguments are passed to the modules.
          extraSpecialArgs = {
            app = example-go-project.packages.x86_64-linux.default;
          };
        };
    in
    {
      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = devTools {
            system = system;
            pkgs = pkgs;
          };
        };
      });

      deploy = {
        nodes = {
          nix-airgapped-vm = {
            hostname = "lima-nix-airgapped-vm";
            sshUser = "adrian-hesketh";
            sshOpts = [ "-F" "/home/adrian-hesketh/.lima/nix-airgapped-vm/ssh.config" ];
            fastConnection = true; # Prefer my connection to the node, instead of letting it download.
            profiles = {
              system = {
                path = deploy-rs.lib.x86_64-linux.activate.custom config "sudo ./bin/activate";
              };
            };
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
