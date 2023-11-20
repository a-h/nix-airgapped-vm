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

      multipass-hosts = pkgs: pkgs.buildGo121Module {
        name = "multipass-hosts";
        # Use my fork until https://github.com/sanderhahn/multipass-hosts/pull/2 is merged.
        src = pkgs.fetchFromGitHub {
          owner = "a-h";
          repo = "multipass-hosts";
          rev = "readonly_print_flag";
          hash = "sha256-quGHVK3d0nJnlGvhwhlcgT3z112ivYtyEAyqXP8tm5c=";
        };
        # Use vendored dependencies for this build.
        vendorHash = null;
      };

      # All of the required development tools.
      devTools = { system, pkgs }: [
        xc.packages.${system}.xc
        deploy-rs.packages.${system}.deploy-rs
        # Waiting for https://github.com/NixOS/nixpkgs/pull/268557 to merge.
        # pkgs.multipass
        (multipass-hosts pkgs)
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
            hostname = "nix-airgapped-vm";
            sshUser = "ubuntu";
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
