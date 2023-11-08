# VM

## Tasks

### create-multipass-vm

Create a new VM. If it already exists, delete it with `multipass delete nix-airgapped-vm`, then `multipass purge`

```sh
multipass launch -n nix-airgapped-vm --disk 10G --cloud-init cloud-init.yaml --verbose
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
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
ssh ubuntu@$NIX_AIRGAPPED_VM_IP
```

### nix-copy-hello

```sh
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
nix copy --to ssh-ng://ubuntu@$NIX_AIRGAPPED_VM_IP "nixpkgs#hello"
nix path-info nixpkgs#hello
```

### nix-run-hello-shell

This command starts a shell in the VM with `hello` installed.

```
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
export NIX_AIRGAPPED_VM_HELLO_LOCATION=`nix path-info nixpkgs#hello`
ssh ubuntu@$NIX_AIRGAPPED_VM_IP "nix shell $NIX_AIRGAPPED_VM_HELLO_LOCATION"
```

### nix-copy-example-go-project-shell

The copy operation doesn't check signatures, as per the extra config added during installation.

Dir: ./example-go-project

```
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
nix copy --derivation --to ssh-ng://ubuntu@$NIX_AIRGAPPED_VM_IP ".#devShells.x86_64-linux.default"
nix path-info --derivation ".#devShells.x86_64-linux.default"
```

### nix-run-example-go-project-shell

This command starts a shell in the VM with `hello` installed.

Dir: ./example-go-project

```
export NIX_AIRGAPPED_VM_IP=`multipass info nix-airgapped-vm --format json | jq -r '.info["nix-airgapped-vm"]["ipv4"][0]'`
export NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION=`nix path-info --derivation ".#devShells.x86_64-linux.default"`
ssh ubuntu@$NIX_AIRGAPPED_VM_IP "nix develop --offline $NIX_AIRGAPPED_VM_EXAMPLE_GO_PROJECT_LOCATION"
```
