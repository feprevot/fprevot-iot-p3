#!/bin/bash

set -e

echo "==> Installing dependencies..."
sudo apt update
sudo apt install -y curl gnupg lsb-release ca-certificates apt-transport-https software-properties-common

# echo "==> Installing Docker..."
# curl -fsSL https://get.docker.com | sudo sh
# sudo usermod -aG docker $USER

echo "==> Installing kubectl..."
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "==> Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "==> Creating K3d cluster..."
k3d cluster create iot-cluster \
  --api-port 6550 \
  -p "8888:80@loadbalancer" \
  --agents 1

echo "==> Configuring kubeconfig..."
mkdir -p ~/.kube
k3d kubeconfig merge iot-cluster --kubeconfig-switch-context

echo "==> Creating namespaces..."
kubectl create namespace argocd || true
kubectl create namespace dev || true

echo "==> Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD pods to be ready..."
while [[ $(kubectl get pods -n argocd --no-headers | grep -v 'Running\|Completed') ]]; do
  echo " Waiting for ArgoCD pods to be ready..."
  sleep 5
done

echo "==> Exposing ArgoCD on port 8888..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "==> Deploying ArgoCD application..."
kubectl apply -f argocd/app.yaml

echo "==> Waiting for app pods to be ready..."
while [[ $(kubectl get pods -n dev --no-headers | grep -v 'Running\|Completed') ]]; do
  echo " Waiting for app pods to be ready..."
  sleep 5
done


echo "==> Done."
echo " Reconnect to your terminal to activate Docker permissions."
