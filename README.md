
# Grafascope

Minimal Helm charts for a complete observability stack built on Grafana and
VictoriaMetrics/Logs/Traces, plus scrapers. The stack is split into three
releases for isolated upgrades and clean defaults.

## Install (three releases)

```bash
# From repo root
helm dependency update ./grafascope/releases/gfs-user
# If migrating from older releases, remove previous cluster-wide RBAC once:
# kubectl delete clusterrole gfs-user-role
# kubectl delete clusterrolebinding gfs-user-binding
helm upgrade --install gfs-user ./grafascope/releases/gfs-user -n grafascope --create-namespace -f grafascope/values.yaml

helm dependency update ./grafascope/releases/core
helm upgrade --install grafascope-core ./grafascope/releases/core -n grafascope -f grafascope/values.yaml

helm dependency update ./grafascope/releases/scrapers
helm upgrade --install grafascope-scrapers ./grafascope/releases/scrapers -n grafascope -f grafascope/values.yaml

# Optional demo apps (metrics/logs/traces generator)
helm dependency update ./demo-apps
helm upgrade --install demo-apps ./demo-apps -n grafascope -f grafascope/values.yaml
```

If you install a service or scraper chart directly, run `helm dependency update` in that
chart directory first. Some charts depend on shared templates in
`grafascope/libs/grafascope-common`.

`grafascope/values.yaml` is the shared values file for the core and scrapers
releases. It contains the global ingress paths/ports and service/scraper overrides.
Installable charts live under `grafascope/releases/*`, while deployable charts
live under `grafascope/services` and `grafascope/scrapers`. Shared library
charts live under `grafascope/libs`.

`gfs-user` uses `global.gfsUser.username` from `grafascope/values.yaml`. The
log collector ServiceAccount name is sourced from the same global value.

Default ingress is configured for a single domain (`localhost`) with subpaths.
Use the `global.*` block in `grafascope/values.yaml` to set hosts, protocol,
paths, and ports in one place. Service charts assume global values.

## Structure

```
grafascope/
  values.yaml
  releases/
    gfs-user/
    core/
    scrapers/
  services/
    grafana/
    victoria-metrics/
    victoria-logs/
    victoria-traces/
  scrapers/
    vmagent/
    victoria-logs-collector/
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
- Scrapers: vmagent (metrics), victoria-logs-collector (logs, DaemonSet)

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
kubectl rollout status daemonset/grafascope-scrapers-victoria-logs-collector -n grafascope

# Uninstall
helm uninstall grafascope-scrapers -n grafascope
helm uninstall grafascope-core -n grafascope
helm uninstall gfs-user -n grafascope
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

The collector remote write must target `/insert/native` and include the namespace
prefix when using `http.pathPrefix`.

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
- `global.gfsUser.username`: shared ServiceAccount name for gfs-user and logs collector.
- `gfs-user.rbac.clusterWide`: must be `true` if the collector uses node metadata (required to start).
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
- `victoria-logs-collector.*`: log collector config (DaemonSet) and `remoteWrite` (use `/insert/native` and include namespace path prefix when enabled).
