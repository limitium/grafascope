FROM grafana/grafana:11.2.0

ARG VM_LOGS_PLUGIN_VERSION="0.23.5"
ARG VM_LOGS_PLUGIN_URL="https://github.com/VictoriaMetrics/victorialogs-datasource/releases/download/v0.23.5/victoriametrics-logs-datasource-v0.23.5.zip"

# Preload plugins for offline environments without grafana-cli (multi-arch safe).
USER root
RUN apk add --no-cache curl unzip \
  && mkdir -p /var/lib/grafana/plugins \
  && curl -fsSL "$VM_LOGS_PLUGIN_URL" -o /tmp/vm-logs.zip \
  && unzip -q /tmp/vm-logs.zip -d /var/lib/grafana/plugins \
  && rm -f /tmp/vm-logs.zip \
  && apk del curl unzip
USER grafana

