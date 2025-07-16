.PHONY: all install cluster clean status argo-sync app-sync

all: install

install:
	bash install.sh

cluster:
	kubectl get nodes
	kubectl get ns

clean:
	k3d cluster delete iot-cluster

status:
	kubectl get pods -n argocd
	kubectl get svc -n argocd

argo-sync:
	kubectl port-forward svc/argocd-server -n argocd 8888:80

app-sync:
	kubectl apply -f argocd/app.yaml

argo-password:
	@echo "Argo CD admin password:"
	kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo