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
