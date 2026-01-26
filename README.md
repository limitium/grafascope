
# Grafascope

Minimal Helm charts for a complete observability stack built on Grafana and
VictoriaMetrics/Logs/Traces. The umbrella chart installs all components with
clean defaults and sane wiring.

## Install (umbrella chart)

```bash
# From repo root
helm dependency update ./grafascope
helm upgrade --install grafascope ./grafascope -n grafascope --create-namespace
```

If you install a component chart directly, run `helm dependency update` in that
chart directory first. Some charts depend on shared templates in
`grafascope-common`.

Default ingress is configured for a single domain (`localhost`) with subpaths.
Use the `global.*` block in `grafascope/values.yaml` to set domain, protocol,
paths, and ports in one place. Component charts assume global values.

- `/grafana`
- `/victoria-metrics`
- `/victoria-logs`
- `/victoria-traces`
- `/vmagent`

Optional: override the host and/or paths at install time:

```bash
helm upgrade --install grafascope ./grafascope -n grafascope --create-namespace \
  --set global.domain=example.local \
  --set global.paths.grafana=/grafana \
  --set global.paths.victoriaMetrics=/victoria-metrics \
  --set global.paths.victoriaLogs=/victoria-logs \
  --set global.paths.victoriaTraces=/victoria-traces
```

## Components and ports

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
kubectl rollout status daemonset/victoria-logs-collector -n grafascope

# Uninstall
helm uninstall grafascope -n grafascope
```

## Ingest data (via Ingress)

These examples assume the default single-domain ingress (`localhost`) with
subpaths. Replace host/path to match your `global.*` values.

### Metrics (Prometheus remote_write)

Send remote_write to VictoriaMetrics:

```
http://localhost/victoria-metrics/api/v1/write
```

### Logs (VictoriaLogs)

VictoriaLogs accepts log insert requests under `/insert/*`. For example:

```
http://localhost/victoria-logs/insert/jsonline
```

### Traces (VictoriaTraces, OTLP HTTP)

OTLP HTTP traces endpoint:

```
http://localhost/victoria-traces/insert/opentelemetry/v1/traces
```

## Values overview

- `grafana.ingress.*`: enable/shape Ingress and hosts.
- `global.domain`: shared ingress host for all components.
- `global.protocol`: protocol for building URLs for Grafana and datasources.
- `global.paths.*`: shared subpaths for ingress routing and app prefixes.
- `global.scrapers.metricsTargets`: optional global scrape targets for vmagent.
- `grafana.server.*`: configure Grafana subpath serving.
- `grafana.datasources.*`: set datasource URLs (defaults to in-cluster services).
- `grafana.pluginsInstall`: toggle `GF_INSTALL_PLUGINS` (disable for offline images).
- `victoria-*.args`: set component flags; use `-http.pathPrefix` for subpath ingress.
- `victoria-*.healthPath`: probe path (set when using `-http.pathPrefix`).
- `victoria-*.persistence.*`: PVC sizing and storage class.
- `victoria-*.persistence.existingClaim`: use an existing PVC instead of creating one.
- `nodeSelector`, `tolerations`, `affinity`: scheduling controls per chart.
- `vmagent.ingress.*`: expose vmagent under `global.paths.vmagent`.
- `victoria-logs-collector.*`: log collector config (DaemonSet) and `remoteWrite`.
