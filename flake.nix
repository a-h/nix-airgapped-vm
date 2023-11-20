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
  };
  outputs = { self, nixpkgs, xc, deploy-rs, ... }:
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
        # multipass
      ];
    in
    {
      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = devTools { system = system; pkgs = pkgs; };
        };
      });

      deploy.nodes = {
        nix-airgapped-vm = {
          hostname = "10.162.19.113";
          sshUser = "ubuntu";
          profiles = {
            hello = {
              user = "ubuntu";
              #path = deploy-rs.lib.x86_64-linux.setActivate nixpkgs.legacyPackages.x86_64-linux.hello "./bin/hello";
              # A derivation containing your required software, and a script to activate it in `${path}/deploy-rs-activate`
              # For ease of use, `deploy-rs` provides a function to easily add the required activation script to any derivation
              # Both the working directory and `$PROFILE` will point to `profilePath`
              path = deploy-rs.lib.x86_64-linux.activate.custom nixpkgs.legacyPackages.x86_64-linux.hello "./bin/hello";
            };
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}

