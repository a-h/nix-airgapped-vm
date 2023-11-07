# Create the Nix store location.
sudo mkdir -p /nix
sudo chmod a+rwx /nix

# Move the Nix configuration to the correct locations.
cp ./dependencies/flake-registry.json /nix/flake-registry.json
cp ./dependencies/nix.conf /nix/nix.conf

# Set the Nix config directory.
echo 'export NIX_CONF_DIR=/nix' >> ~/.bash_profile

# Untar the installer and run it.
tar -xf ./dependencies/nix-2.16.1-x86_64-linux.tar.xz
nix-2.16.1-x86_64-linux/install --no-daemon
