# homelab

My Homelab bootstrap & configuration repository.

## Environment Setup

Current environment:

- Ubuntu 22.04 LTS Server Edition (Control Node, Worker Node)
- Raspberry Pi 3 B+ (Worker Node)

### Disable Swap

Kubernetes does not have stable swap support (yet). See [reference](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin).

To disable swap on running host:

```bash
sudo swapoff -a
```

To disable swap on host restart:
```bash
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
```
