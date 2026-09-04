# URL Shortener on Alibaba Cloud (ACK)

Deploys [ccc-56/URL-shortern](https://github.com/ccc-56/URL-shortern) (Node.js + Redis, nginx front) to
Alibaba Cloud Container Service for Kubernetes with Terraform, multi-stage Docker builds and GitHub Actions.

```
Internet ──> CLB (Service type=LoadBalancer) ──> nginx Pods ──/api,/r──> app Service (ClusterIP) ──> app Pods ──> redis-0 (StatefulSet, ESSD PVC)
                                                     └── / static files
```

| Layer | Alibaba Cloud | In this repo |
|---|---|---|
| Network | VPC, 2 node vSwitches + 2 pod vSwitches (2 zones), Enhanced NAT + EIP, security group | `terraform/network.tf` |
| Cluster | ACK Pro managed, Terway ENIIP, IPVS kube-proxy, CSI, node pool 2×ecs.c6.large | `terraform/ack.tf` |
| Registry | ACR personal edition, 2 private repos | `terraform/acr.tf` |
| Images | `Dockerfile-app` (deps → runtime, non-root), `Dockerfile-nginx` (assets → nginx) | root |
| Workloads | Namespace, Redis StatefulSet + headless Service, app Deployment + ClusterIP, nginx Deployment + CLB | `k8s/` (kustomize) |
| CI/CD | test → build/push to ACR → `kubectl apply -k` | `.github/workflows/deploy.yml` |

## 1. Infrastructure

```bash
export ALICLOUD_ACCESS_KEY=... ALICLOUD_SECRET_KEY=...   # RAM user, see permissions below
cd terraform
cp terraform.tfvars.example terraform.tfvars              # set a unique acr_namespace
terraform init
terraform apply                                           # ~15 min
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes -o wide
```

RAM permissions for the Terraform user: `AliyunCSFullAccess`, `AliyunECSFullAccess`, `AliyunVPCFullAccess`,
`AliyunSLBFullAccess`, `AliyunNATGatewayFullAccess`, `AliyunEIPFullAccess`, `AliyunContainerRegistryFullAccess`,
`AliyunRAMReadOnlyAccess`.

Approximate cost while running: ACK Pro control plane ≈ ¥0.64/h, 2×ecs.c6.large ≈ ¥0.8/h, NAT + EIP + CLB pay-per-use.
`terraform destroy` removes everything (delete the `url-shortener` namespace first so the CLB and PVC disk are released).

## 2. Images

```bash
REG=registry.cn-hangzhou.aliyuncs.com/<acr_namespace>
docker login $REG                                      # ACR username = Alibaba Cloud account, password = ACR access password
docker build -f Dockerfile-app   -t $REG/url-shortener-app:v1   .
docker build -f Dockerfile-nginx -t $REG/url-shortener-nginx:v1 .
docker push $REG/url-shortener-app:v1 && docker push $REG/url-shortener-nginx:v1
```

Multi-stage notes: the app image ends up as `node:20-alpine` + production `node_modules` + `src/` only, running as a
non-root user; dev dependencies never enter the final image. Tests run in CI against a Redis service container.

## 3. Deploy

```bash
kubectl create ns url-shortener
kubectl -n url-shortener create secret docker-registry acr-pull \
  --docker-server=registry-vpc.cn-hangzhou.aliyuncs.com --docker-username=<account> --docker-password=<acr password>
kubectl -n url-shortener patch serviceaccount default -p '{"imagePullSecrets":[{"name":"acr-pull"}]}'

cd k8s
kustomize edit set image \
  registry.cn-hangzhou.aliyuncs.com/CHANGE_ME/url-shortener-app=registry-vpc.cn-hangzhou.aliyuncs.com/<ns>/url-shortener-app:v1 \
  registry.cn-hangzhou.aliyuncs.com/CHANGE_ME/url-shortener-nginx=registry-vpc.cn-hangzhou.aliyuncs.com/<ns>/url-shortener-nginx:v1
kubectl apply -k .
kubectl -n url-shortener get svc url-shortener-nginx -w        # wait for EXTERNAL-IP (CLB)
curl -X POST http://<CLB-IP>/api/shorten -H 'content-type: application/json' -d '{"url":"https://aliyun.com"}'
```

Inside the cluster nginx proxies to `url-shortener-app.url-shortener.svc.cluster.local:3000` and resolves it through
CoreDNS (`resolver` is filled from the Pod's `/etc/resolv.conf` at container start), so scaling the app changes
nothing in nginx — kube-proxy (IPVS) load-balances the ClusterIP across the ready Pods.

## 4. GitHub Actions

Repository settings:

* Variable `ACR_NAMESPACE`
* Secrets `ACR_USERNAME`, `ACR_PASSWORD`, `KUBECONFIG_B64` (`base64 -w0 terraform/kubeconfig`)

Every push to `main` runs the tests, builds both images tagged with the short SHA, pushes to ACR and rolls the
Deployments; pull requests only run the tests.

## 5. Local run

```bash
docker compose up --build       # http://localhost:8080
```

## Production hardening (not included)

* Replace the in-cluster Redis with ApsaraDB for Redis and point `REDIS_URL` at it.
* Use ALB Ingress + free HTTPS cert instead of raw CLB; set `BASE_URL` to the domain.
* Terraform remote state in OSS, ACR Enterprise Edition with image scanning, Argo CD for GitOps.
* SLS (Logtail) for logs, ARMS Prometheus for metrics.
