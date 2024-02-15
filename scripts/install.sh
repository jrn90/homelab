#!/usr/bin/env bash
# 
# Installs prerequisits for kubernetes

set -o errexit
set -o nounset
set -o pipefail

ARCH=arm64
TMP_DIR=/tmp/downloads
CONTAINERD_DIR=/etc/containerd
CONTAINERD_CONFIG=/etc/containerd/config.toml
BIN_DIR=/usr/local/bin

VERSION_CNI=1.4.0
VERSION_CONTAINERD=1.7.13
VERSION_CRICTL=1.29.0
VERSION_KUBECTL=1.29.1
VERSION_KUBELET=1.29.2
VERSION_RUNC=1.1.12

echo 'Creating directories'
sudo mkdir -p "${TMP_DIR}"
sudo mkdir -p /usr/local/bin/systemd/system/
sudo mkdir -p /opt/cni/bin
sudo mkdir -p /etc/containerd/

# Downloads
echo 'Downloading containerd'
curl --progress-bar --location https://github.com/containerd/containerd/releases/download/v"${VERSION_CONTAINERD}"/containerd-"${VERSION_CONTAINERD}"-linux-"${ARCH}".tar.gz --output "${TMP_DIR}"/containerd-"${VERSION_CONTAINERD}"-linux."${ARCH}".tar.gz
echo 'Downloading systemd service file'
curl --progress-bar --location https://raw.githubusercontent.com/containerd/containerd/main/containerd.service --output "${TMP_DIR}"/containerd.service
echo 'Downloading runc'
curl --progress-bar --location https://github.com/opencontainers/runc/releases/download/v"${VERSION_RUNC}"/runc."${ARCH}" --output "${TMP_DIR}"/runc."${ARCH}"
echo 'Downloading cni plugins'
curl --progress-bar --location https://github.com/containernetworking/plugins/releases/download/v"${VERSION_CNI}"/cni-plugins-linux-"${ARCH}"-v"${VERSION_CNI}".tgz --output "${TMP_DIR}"/cni-plugins-linux-"${ARCH}"-v"${VERSION_CNI}".tgz 
echo 'Downloading kubectl'
curl --progress-bar --location https://dl.k8s.io/release/v"${VERSION_KUBECTL}"/bin/linux/"${ARCH}"/kubectl --output "${TMP_DIR}"/kubectl
echo 'Downloading crictl'
curl --progress-bar --location https://github.com/kubernetes-sigs/cri-tools/releases/download/v"${VERSION_CRICTL}"/crictl-v"${VERSION_CRICTL}"-linux-"${ARCH}".tar.gz --output "${TMP_DIR}"/crictl-v"${VERSION_CRICTL}"-linux-"${ARCH}".tar.gz
echo 'Downloading kubelet'
curl --progress-bar --location https://dl.k8s.io/release/v"${VERSION_KUBELET}"/bin/linux/${ARCH}/kubelet --output "${TMP_DIR}"/kubelet
echo 'Downloading kubeadm'
curl --progress-bar --location https://dl.k8s.io/release/v"${VERSION_KUBELET}"/bin/linux/${ARCH}/kubeadm --output "${TMP_DIR}"/kubeadm

# Installs
echo 'Installing containerd'
tar Cxzf /usr/local "${TMP_DIR}"/containerd-"${VERSION_CONTAINERD}"-linux."${ARCH}".tar.gz
echo 'Installing systemd service files'
cp "${TMP_DIR}"/containerd.service /usr/local/lib/systemd/system/containerd.service 
echo 'Installing runc'
install -m 755 "${TMP_DIR}"/runc."${ARCH}" /usr/local/sbin/runc
echo 'Installing cni plugins'
tar Cxzf /opt/cni/bin "${TMP_DIR}"/cni-plugins-linux-"${ARCH}"-v"${VERSION_CNI}".tgz
echo 'Installing kubectl'
sudo install -o root -g root -m 0755 "${TMP_DIR}"/kubectl "${BIN_DIR}"/kubectl
echo 'Installing crictl'
tar Cxzf "${BIN_DIR}" "${TMP_DIR}"/crictl-v"${VERSION_CRICTL}"-linux-"${ARCH}".tar.gz
echo 'Installing kubelet'
cp "${TMP_DIR}"/kubelet "${BIN_DIR}"/kubelet
chmod +x "${BIN_DIR}"/kubelet
echo 'Installing kubeadm'
cp "${TMP_DIR}"/kubeadm "${BIN_DIR}"/kubeadm
chmod +x "${BIN_DIR}"/kubeadm

# Config
touch "${CONTAINERD_CONFIG}"
containerd config default > "${CONTAINERD_CONFIG}"
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/" "${CONTAINERD_CONFIG}"

curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${BIN_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${BIN_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Start services
echo 'Reloading daemon'
systemctl daemon-reload
echo 'Enabling containerd service'
systemctl enable --now containerd 
echo 'Enabling kubelet service'
systemctl enable --now kubelet

# Cleanup
echo 'Deleting temp files'
sudo rm -rf /tmp/downloads
