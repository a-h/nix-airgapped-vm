{
  description = "example-go-project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xc = {
      url = "github:joerdav/xc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, gitignore, xc }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = forAllSystems ({ system, pkgs }: {
        default = pkgs.buildGo121Module {
          name = "example-go-project";
          src = gitignore.lib.gitignoreSource ./.;
          # Use vendored dependencies for this build.
          vendorSha256 = null;
        };
      });

      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs;
            [
              hello
              go_1_21
              gotools
              xc.packages.${system}.xc
            ];
        };
      });
    };
}
