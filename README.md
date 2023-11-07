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

```sh
multipass transfer --recursive ./dependencies nix-airgapped-vm:.
cat install-nix.sh | multipass exec nix-airgapped-vm -- bash -
```
