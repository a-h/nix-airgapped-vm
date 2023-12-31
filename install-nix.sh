# Create the Nix store location.
sudo mkdir -p /nix
sudo chmod a+rwx /nix

# Move the Nix configuration to the correct locations.
cp ./dependencies/flake-registry.json /nix/flake-registry.json

# Use the Determinate systems installer.
./dependencies/nix-installer-x86_64-linux install --no-confirm --nix-package-url=./dependencies/nix-2.18.1-x86_64-linux.tar.xz --extra-conf 'flake-registry = /nix/flake-registry.json' --extra-conf 'require-sigs = false'
