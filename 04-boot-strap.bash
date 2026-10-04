#!/bin/bash

MODE=${1:-prod}

cd 01-bootstrap

kubectl apply -f argocd-ing.yaml

#if [ "$MODE" = "dev" ]; then
  # ให้ปรับ repoURL ให้ชี้ตรงไปที่ remote GIT ด้วย เพื่อให้ ArgoCD ไป sync มาจากตรงนั้นแทน
  DATA_PLANE_REMOTE_REPO=https://github.com/wintech-thai/nap-k3s-server-002.git

  sed -i "s|^\([[:space:]]*\)repoURL: .*|\1repoURL: ${DATA_PLANE_REMOTE_REPO}|g" argocd-bootstrap-data-plane.yaml
#fi

echo "Deploying data plane"
kubectl apply -f argocd-bootstrap-data-plane.yaml

kubectl apply -f argocd-cluster-secret.yaml

GIT_USER=$(kubectl get secret initial-secret -n default -o jsonpath='{.data.GIT_USER}' | base64 -d)
GIT_PASSWORD=$(kubectl get secret initial-secret -n default -o jsonpath='{.data.GIT_PASSWORD}' | base64 -d)

YAML_FILE="argocd-local-repo.yaml"
cp ${YAML_FILE} ${YAML_FILE}.tmp
sed -i "s|<<GITEA_USERNAME>>|${GIT_USER}|g" ${YAML_FILE}.tmp
sed -i "s|<<GITEA_PASSWORD>>|${GIT_PASSWORD}|g" ${YAML_FILE}.tmp 
kubectl apply -f ${YAML_FILE}.tmp

cd ..