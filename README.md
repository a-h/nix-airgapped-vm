# VM

## Tasks

### create-multipass-vm

Create a new VM. If it already exists, delete it with `multipass delete nix-airgapped-vm`, then `multipass purge`

```sh
multipass launch -n nix-airgapped-vm --disk 10G --cloud-init cloud-init.yaml --verbose
```

### add-multipass-vm-dns

```sh
nix develop --command multipass-hosts -print=true -update=false > hosts
echo "About to overwrite hosts file..."
sudo mv hosts /etc/hosts
```

### view-startup-logs

You can check the startup logs to check that the commands in cloud-init.yaml were successful.

```sh
multipass exec nix-airgapped-vm -- sudo cat /var/log/cloud-init-output.log
```

### install-nix

The installer comes from https://github.com/DeterminateSystems/nix-installer/releases

The binary comes from https://releases.nixos.org/nix/nix-2.18.1/nix-2.18.1-x86_64-linux.tar.xz

```sh
multipass transfer --recursive ./dependencies nix-airgapped-vm:.
cat install-nix.sh | multipass exec nix-airgapped-vm -- bash -
```

### enable-ssh

```sh
cat enable-ssh.sh | multipass exec nix-airgapped-vm -- bash -
```

### ssh

```sh
ssh ubuntu@nix-airgapped-vm
```

### ssh-without-dns

```sh
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
ssh ubuntu@$NIX_AIRGAPPED_VM_IP
```

### nix-copy-hello

```sh
nix copy --to ssh-ng://ubuntu@nix-airgapped-vm "nixpkgs#hello"
nix path-info nixpkgs#hello
```

### nix-run-hello-shell

This command starts a shell in the VM with `hello` installed.

```
export NIX_AIRGAPPED_VM_HELLO_LOCATION=`nix path-info nixpkgs#hello`
ssh ubuntu@nix-airgapped-vm "nix shell $NIX_AIRGAPPED_VM_HELLO_LOCATION"
```

### nix-copy-example-go-project-shell

The copy operation doesn't check signatures, as per the extra config added during installation.

Dir: ./example-go-project

```
nix copy --to ssh-ng://ubuntu@nix-airgapped-vm ".#devShells.x86_64-linux.default"
nix copy --derivation --to ssh-ng://ubuntu@nix-airgapped-vm ".#devShells.x86_64-linux.default"
nix path-info --derivation ".#devShells.x86_64-linux.default"
```

### nix-run-example-go-project-shell

This command starts a shell in the VM with `hello` installed.

Dir: ./example-go-project

```
export NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION=`nix path-info --derivation ".#devShells.x86_64-linux.default"`
ssh ubuntu@nix-airgapped-vm "nix develop --offline $NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION"
```

### nix-example-go-project-copy-source

```
multipass transfer --recursive ./example-go-project nix-airgapped-vm:.
```

### nix-build-docker-app

Build the Docker app image using Nix and import it to the local Docker daemon.

Dir: example-go-project

```sh
nix build .#dockerImageApp
docker load < result
```

### nix-build-docker-tools

Build the Docker tools image using Nix and import it to the local Docker daemon.

Dir: example-go-project

```sh
nix build .#dockerImageTools
docker load < result
```

### docker-run-app

Run the Docker image created by `nix-build-docker-app`.

```sh
docker run --rm -it example-go-project:latest
```

### docker-run-tools

Run the Docker image created by `nix-build-docker-tools`.

```sh
docker run --rm -it example-go-project:tools-latest
```

### sbom

Dir: example-go-project

```sh
nix run github:tiiuae/sbomnix#sbomnix -- --type both `nix path-info .`
```

### sbom-graph

Dir: example-go-project

```sh
nix run github:tiiuae/sbomnix#nixgraph -- --buildtime --depth=1 `nix path-info .#dockerImageApp`
```

### nix-deploy

```sh
nix develop --command deploy
```

### logs

```sh
ssh ubuntu@nix-airgapped-vm journalctl -u example-go-project
```
