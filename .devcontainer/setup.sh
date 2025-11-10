#!/usr/bin/env bash
set -ouo pipefail
apt-get update && apt-get install -y curl gnupg ca-certificates
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin
# helm
curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# k3d
curl -s https://raw/githubusercontent.com/k3d-io/k3d/main/install.sh | bash
