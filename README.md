# VM

## Tasks

### create-lima-vm

See docs at https://lima-vm.io/docs/reference/limactl_create/

If the VM exists, you will need to delete it with `stop` and `delete` commands.

```bash
limactl stop nix-airgapped-vm --tty=false || true
limactl delete nix-airgapped-vm --tty=false || true
limactl create --name=nix-airgapped-vm --memory=2 --cpus=1 --tty=false template://rocky-8
limactl start nix-airgapped-vm --tty=false
```

### disable-lima-vm-outbound-traffic

```bash
limactl shell nix-airgapped-vm sudo dnf install firewalld -y
limactl shell nix-airgapped-vm sudo bash -c 'systemctl enable --now firewalld'
limactl shell nix-airgapped-vm sudo iptables -t filter -I OUTPUT 1 -m state --state NEW -j DROP
```

### install-nix

The installer comes from https://github.com/DeterminateSystems/nix-installer/releases

The binary comes from https://releases.nixos.org/nix/nix-2.18.1/nix-2.18.1-x86_64-linux.tar.xz

```bash
limactl copy ./dependencies nix-airgapped-vm: --recursive
cat install-nix.sh | limactl shell nix-airgapped-vm
# Setup SELinux policy to enable system-manager.
cat setup-selinux.sh | limactl shell nix-airgapped-vm
```

### ssh

```bash
ssh -F $HOME/.lima/nix-airgapped-vm/ssh.config lima-nix-airgapped-vm
```

### nix-copy-hello

Copies `hello` from the nixpkgs to the remote machine, and installs it in the default profile.

```bash
export NIX_SSHOPTS="-F $HOME/.lima/nix-airgapped-vm/ssh.config" 
nix copy --to ssh-ng://lima-nix-airgapped-vm "nixpkgs#hello"
export NIX_AIRGAPPED_VM_HELLO_LOCATION=`nix path-info nixpkgs#hello`
limactl shell nix-airgapped-vm nix profile install $NIX_AIRGAPPED_VM_HELLO_LOCATION
```

### nix-copy-example-go-project-shell

The copy operation doesn't check signatures, as per the extra config added during installation.

Dir: ./example-go-project

```bash
export NIX_SSHOPTS="-F $HOME/.lima/nix-airgapped-vm/ssh.config" 
nix copy --to ssh-ng://lima-nix-airgapped-vm ".#devShells.x86_64-linux.default"
nix copy --derivation --to ssh-ng://lima-nix-airgapped-vm ".#devShells.x86_64-linux.default"
nix path-info --derivation ".#devShells.x86_64-linux.default"
```

### nix-run-example-go-project-shell

This command starts a shell in the VM with `hello` installed.

Dir: ./example-go-project

```bash
export NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION=`nix path-info --derivation ".#devShells.x86_64-linux.default"`
limactl shell nix-airgapped-vm nix develop --offline $NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION
```

### nix-example-go-project-copy-source

```bash
limactl copy ./example-go-project nix-airgapped-vm: --recursive
```

### nix-build-docker-app

Build the Docker app image using Nix and import it to the local Docker daemon.

Dir: example-go-project

```bash
nix build .#dockerImageApp
docker load < result
```

### nix-build-docker-tools

Build the Docker tools image using Nix and import it to the local Docker daemon.

Dir: example-go-project

```bash
nix build .#dockerImageTools
docker load < result
```

### docker-run-app

Run the Docker image created by `nix-build-docker-app`.

```bash
docker run --rm -it example-go-project:latest
```

### docker-run-tools

Run the Docker image created by `nix-build-docker-tools`.

```bash
docker run --rm -it example-go-project:tools-latest
```

### sbom

Dir: example-go-project

```bash
nix run github:tiiuae/sbomnix#sbomnix -- --type both `nix path-info .`
```

### sbom-graph

Dir: example-go-project

```bash
nix run github:tiiuae/sbomnix#nixgraph -- --buildtime --depth=1 `nix path-info .#dockerImageApp`
```

### nix-deploy

```bash
nix develop --command deploy
```

### nix-update-flake-lock

```bash
nix flake lock --update-input example-go-project
```

### logs

```bash
limactl shell nix-airgapped-vm sudo journalctl -u example-go-project
```
