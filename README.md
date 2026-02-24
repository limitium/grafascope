
# Grafascope

Minimal Helm charts for a complete observability stack built on Grafana and
VictoriaMetrics/Logs/Traces, plus scrapers. The stack is split into multiple
releases for isolated upgrades and clean defaults.

## Install

### Quick install (script)

From a **consumer repo** (with grafascope as submodule and `values/<env>.yaml`):

```bash
./grafascope/scripts/update-and-upgrade.sh grafascope-dev all
```

This installs: core (Grafana + VictoriaMetrics/Logs/Traces), vmagent, log-tailer
(Fluent Bit), and demo-apps. It does not install gfs-user or vlagent—use manual
commands below if needed.

```bash
# Other actions
./grafascope/scripts/update-and-upgrade.sh grafascope-dev core
./grafascope/scripts/update-and-upgrade.sh grafascope-dev vmagent
./grafascope/scripts/update-and-upgrade.sh grafascope-dev fluent-bit
./grafascope/scripts/update-and-upgrade.sh grafascope-dev demo-apps
./grafascope/scripts/update-and-upgrade.sh grafascope-dev delete-all
```

### Manual install (all releases)

```bash
# From repo root
helm dependency update ./grafascope/releases/gfs-user
# If migrating from older releases, remove previous cluster-wide RBAC once:
# kubectl delete clusterrole gfs-user-role
# kubectl delete clusterrolebinding gfs-user-binding
helm upgrade --install gfs-user ./grafascope/releases/gfs-user -n grafascope --create-namespace -f grafascope/values.yaml

helm dependency update ./grafascope/releases/core
helm upgrade --install grafascope-core ./grafascope/releases/core -n grafascope -f grafascope/values.yaml

# Scrapers
helm dependency update ./grafascope/releases/vmagent
helm upgrade --install grafascope-vmagent ./grafascope/releases/vmagent -n grafascope -f grafascope/values.yaml

# Log collectors (use one or the other)
# vlagent: VictoriaLogs collector (K8s API)
helm dependency update ./grafascope/releases/vlagent
helm upgrade --install grafascope-vlagent ./grafascope/releases/vlagent -n grafascope -f grafascope/values.yaml
# log-tailer: Fluent Bit (no K8s API, path-based extraction)
helm dependency update ./grafascope/releases/log-tailer
helm upgrade --install grafascope-log-tailer ./grafascope/releases/log-tailer -n grafascope -f grafascope/values.yaml

# Optional demo apps
helm dependency update ./demo-apps
helm upgrade --install demo-apps ./demo-apps -n grafascope -f grafascope/values.yaml
```

If you install a service or scraper chart directly, run `helm dependency update` in that
chart directory first. Some charts depend on shared templates in
`grafascope/libs/grafascope-common`.

`grafascope/values.yaml` is the shared values file for the core and scraper
releases. It contains the global ingress paths/ports and service/scraper overrides.
Installable charts live under `grafascope/releases/*`, while deployable charts
live under `grafascope/services` and `grafascope/scrapers`. Shared library
charts live under `grafascope/libs`.

`gfs-user` uses `global.gfsUser.username` from `grafascope/values.yaml`. By default it creates a ServiceAccount and namespace-scoped Role/RoleBinding in the release namespace; set `gfs-user.rbac.clusterWide: true` for ClusterRole/ClusterRoleBinding (e.g. when the collector needs node metadata). The log collector ServiceAccount name is sourced from the same global value.

Default ingress is configured for a single domain (`localhost`) with subpaths.
Use the `global.*` block in `grafascope/values.yaml` to set hosts, protocol,
paths, and ports in one place. Service charts assume global values.

## Using as a Git submodule

Use this repo as a template by adding it as a submodule in a consumer repo.
Override resources, storage, logs ingest URL, and other env-specific settings
without forking.

### 1. Add the submodule

From your consumer repo root:

```bash
git submodule add https://github.com/your-org/grafascope.git grafascope
git submodule update --init --recursive
```

### 2. Consumer repo structure

```
your-deployments/
├── grafascope/              # submodule
├── values/
│   └── grafascope-dev.yaml  # env-specific overrides
└── .gitmodules
```

### 3. Environment-specific values

Create `values/${ENV}.yaml` with overrides. These are merged over the base
`grafascope/values.yaml`. Typical overrides:

```yaml
# values/prod.yaml
global:
  clusterName: prod
  domain: obs.example.com

fluent-bit:
  config:
    outputs: |
      [OUTPUT]
          Name http
          Host victoria-logs
          URI /prod/victoria-logs/insert/jsonline...
  resources:
    limits:
      memory: 2G

victoria-logs:
  persistence:
    size: 50Gi

victoria-metrics:
  persistence:
    size: 100Gi

vmagent:
  scrapeTargets: [...]
```

### 4. Deploy

From the **consumer repo root**:

```bash
./grafascope/scripts/update-and-upgrade.sh grafascope-dev all
./grafascope/scripts/update-and-upgrade.sh grafascope-dev core --dry-run
```

To use explicit values files instead of env:

```bash
VALUES="grafascope/values.yaml ../values/grafascope-dev.yaml" ./grafascope/scripts/update-and-upgrade.sh grafascope-dev all
```

### 5. Updating the submodule

```bash
cd grafascope && git pull origin main && cd ..
git add grafascope
git commit -m "Update grafascope submodule"
```

---

Ingress requires **ingress-nginx** (Ingress class `nginx`). Install it separately
if needed. For **k3d**: create the cluster with port 80 mapped so
`http://localhost/<namespace>/grafana` works:
`k3d cluster create <name> -p 80:80@server:0 -p 443:443@server:0`. If the cluster
was created without that, run
`kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80`
and open `http://localhost:8080/<namespace>/grafana`.

## gfs-user RBAC (copy/paste)

Use this if you want to create the ServiceAccount + RBAC manually in the Kubernetes UI
instead of installing the `gfs-user` chart. The chart default is **namespace scope** (Role + RoleBinding in the release namespace). Below is the **cluster-wide** variant (ClusterRole + ClusterRoleBinding); for namespace-only, use Role/RoleBinding and omit cluster-scoped resources (e.g. `nodes`, `namespaces`, `persistentvolumes`, `componentstatuses`).

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gfs-user
  namespace: grafascope
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gfs-user-role
rules:
  - apiGroups:
      - ""
      - apps
      - autoscaling
      - batch
      - extensions
      - policy
      - rbac.authorization.k8s.io
    resources:
      - pods
      - componentstatuses
      - configmaps
      - daemonsets
      - deployments
      - deployments/scale
      - events
      - endpoints
      - horizontalpodautoscalers
      - ingress
      - jobs
      - cronjobs
      - limitranges
      - namespaces
      - nodes
      - persistentvolumes
      - persistentvolumeclaims
      - resourcequotas
      - replicasets
      - replicationcontrollers
      - serviceaccounts
      - services
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gfs-user-binding
subjects:
  - kind: ServiceAccount
    name: gfs-user
    namespace: grafascope
roleRef:
  kind: ClusterRole
  name: gfs-user-role
  apiGroup: rbac.authorization.k8s.io
```

If you want namespace-only access, replace `ClusterRole`/`ClusterRoleBinding` with
`Role`/`RoleBinding` and remove cluster-scoped resources like `nodes`/`namespaces`.
For a minimal collector-only RBAC, you can reduce the rules to just:

```yaml
rules:
  - apiGroups: [""]
    resources: ["nodes", "namespaces", "pods"]
    verbs: ["get", "list", "watch"]
```

Node access is required for the collector to start; remove `nodes` only if you
disable node metadata and accept missing node-based filters.

## Structure

```
grafascope/
  values.yaml
  releases/
    gfs-user/
    core/
    vmagent/
    vlagent/
    log-tailer/
  services/
    grafana/
    victoria-metrics/
    victoria-logs/
    victoria-traces/
  scrapers/
    vmagent/
    victoria-logs-collector/
    fluent-bit/
  libs/
    grafascope-common/
    victoria-common/
```

Ingress paths are namespace-prefixed:

- `/<namespace>/grafana`
- `/<namespace>/victoria-metrics`
- `/<namespace>/victoria-logs`
- `/<namespace>/victoria-traces`
- `/<namespace>/vmagent`

Optional: override the host and/or paths at install time:

```bash
helm upgrade --install grafascope-core ./grafascope/releases/core -n grafascope \
  -f grafascope/values.yaml \
  --set global.domain=example.local \
  --set global.paths.grafana=/grafana \
  --set global.paths.victoriaMetrics=/victoria-metrics \
  --set global.paths.victoriaLogs=/victoria-logs \
  --set global.paths.victoriaTraces=/victoria-traces
```

## Services and ports

- Grafana: 3000
- VictoriaMetrics: 8428
- VictoriaLogs: 9428
- VictoriaTraces: 9410
- Dedicated releases: vmagent (metrics), vlagent (VictoriaLogs collector, DaemonSet), log-tailer (Fluent Bit)

## Useful commands

```bash
# Status
kubectl get pods -n grafascope
kubectl get ingress -n grafascope

# Rollouts
kubectl rollout status deployment/grafana -n grafascope
kubectl rollout status deployment/vmagent -n grafascope
kubectl rollout status statefulset/victoria-metrics -n grafascope
kubectl rollout status statefulset/victoria-logs -n grafascope
kubectl rollout status statefulset/victoria-traces -n grafascope
# Log collector (Fluent Bit; if using log-tailer)
kubectl rollout status daemonset/grafascope-log-tailer-fluent-bit -n grafascope
# Log collector (vlagent; if using grafascope-vlagent)
kubectl rollout status daemonset/grafascope-vlagent-victoria-logs-collector -n grafascope

# Uninstall (matches scripts/update-and-upgrade.sh delete-all, plus gfs-user/vlagent)
helm uninstall demo-apps -n grafascope
helm uninstall grafascope-log-tailer -n grafascope
helm uninstall grafascope-vmagent -n grafascope
helm uninstall grafascope-core -n grafascope
helm uninstall grafascope-vlagent -n grafascope  # if installed
helm uninstall gfs-user -n grafascope            # if installed
```

## Ingest data (via Ingress)

These examples assume the default single-domain ingress (`localhost`) with
namespace-prefixed subpaths. Replace host/path to match your `global.*` values.

### Metrics (Prometheus remote_write)

Send remote_write to VictoriaMetrics:

```
http://localhost/<namespace>/victoria-metrics/api/v1/write
```

### Logs (VictoriaLogs)

VictoriaLogs accepts log insert requests under `/insert/*`. For example:

```
http://localhost/<namespace>/victoria-logs/insert/jsonline
```

The Fluent Bit log-tailer sends to
`/<namespace>/victoria-logs/insert/jsonline` (path configured via
`fluent-bit.config.outputs` and `global.paths`). The vlagent collector remote
write targets `/insert/native` and must include the namespace path prefix when
`http.pathPrefix` is enabled.

### Traces (VictoriaTraces, OTLP HTTP)

OTLP HTTP traces endpoint:

```
http://localhost/<namespace>/victoria-traces/insert/opentelemetry/v1/traces
```

## Values overview

- `grafana.ingress.*`: enable/shape Ingress and hosts.
- `global.domain`/`global.hosts`: shared ingress host(s) for all services.
- `global.protocol`: protocol for building URLs for Grafana and datasources.
- `global.paths.*`: shared subpaths for ingress routing and app prefixes (camelCase keys like `victoriaMetrics`).
- `global.clusterName`: cluster label added to logs for multi-cluster filtering.
- `global.gfsUser.username`: shared ServiceAccount name for gfs-user and logs collector.
- `gfs-user.rbac.clusterWide`: default `false` (ServiceAccount + Role/RoleBinding in release namespace). Set `true` for ClusterRole/ClusterRoleBinding if the collector needs node metadata.
- `global.scrapers.metricsTargets`: optional global scrape targets for vmagent.
- `grafana.resources`, `victoria-*.resources`, `vmagent.resources`: centralized resource defaults in this file.
- `grafana.server.*`: configure Grafana subpath serving.
- `grafana.datasources.*`: set datasource URLs (defaults to in-cluster services).
- `grafana.pluginsInstall`: toggle `GF_INSTALL_PLUGINS` (disable for offline images).
- `victoria-*.args`: set service flags; use `-http.pathPrefix` for subpath ingress.
- `victoria-*.healthPath`: probe path (set when using `-http.pathPrefix`).
- `victoria-*.persistence.*`: PVC sizing and storage class.
- `victoria-*.persistence.existingClaim`: use an existing PVC instead of creating one.
- `nodeSelector`, `tolerations`, `affinity`: scheduling controls per chart.
- `vmagent.ingress.*`: expose vmagent under `global.paths.vmagent`.
- `fluent-bit.*`: log-tailer (Fluent Bit DaemonSet) config, resources, Lua extraction of pod/namespace/container/service from log paths, hostPath mounts; runs as root to read host logs.
- `victoria-logs-collector.*`: vlagent log collector (DaemonSet) config and `remoteWrite` (use `/insert/native` and include namespace path prefix when enabled).
