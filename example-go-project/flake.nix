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
      devTools = { system, pkgs }: with pkgs; [
        go_1_21
        gotools
        xc.packages.${system}.xc
      ];

      # App to build.
      app = pkgs: pkgs.buildGo121Module {
        name = "example-go-project";
        src = gitignore.lib.gitignoreSource ./.;
        # Use vendored dependencies for this build.
        vendorHash = null;
      };

      # Docker user.
      dockerUser = pkgs: pkgs.runCommand "user" { } ''
        mkdir -p $out/etc
        echo "user:x:1000:1000:user:/home/user:/bin/false" > $out/etc/passwd
        echo "user:x:1000:" > $out/etc/group
        echo "user:!:1::::::" > $out/etc/shadow
      '';
      # Docker app.
      dockerImageApp = pkgs: pkgs.dockerTools.buildImage {
        name = "example-go-project";
        tag = "latest";

        copyToRoot = [
          # Uncomment the coreutils and bash if you want to be able to use a shell environment
          # inside the container.
          # pkgs.coreutils
          # pkgs.bash
          (dockerUser pkgs)
          (app pkgs)
        ];
        config = {
          Cmd = [ "example-go-project" ];
          User = "user:user";
          Env = [ "ADD_ENV_VARIABLES=1" ];
          ExposedPorts = {
            "8080/tcp" = { };
          };
        };
      };
      dockerImageTools = { system, pkgs }: pkgs.dockerTools.buildImage {
        name = "example-go-project";
        tag = "tools-latest";

        copyToRoot = [
          pkgs.coreutils
          pkgs.bash
        ] ++ (devTools { system = system; pkgs = pkgs; });
        config = {
          Cmd = [ "bash" ];
        };
      };
    in
    {
      packages = forAllSystems ({ system, pkgs }: {
        default = app pkgs;
        dockerImageApp = dockerImageApp pkgs;
        dockerImageTools = dockerImageTools { system = system; pkgs = pkgs; };
      });

      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = devTools { system = system; pkgs = pkgs; };
        };
      });
    };
}
