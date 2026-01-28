FROM grafana/grafana:11.2.0

ARG VM_LOGS_PLUGIN_VERSION="0.23.5"
ARG VM_LOGS_PLUGIN_URL="https://github.com/VictoriaMetrics/victorialogs-datasource/releases/download/v0.23.5/victoriametrics-logs-datasource-v0.23.5.zip"

# Preload plugins for offline environments without grafana-cli (multi-arch safe).
# Install to /usr/share/grafana/plugins to avoid PVC override at /var/lib/grafana.
USER root
RUN apk add --no-cache curl unzip \
  && mkdir -p /usr/share/grafana/plugins \
  && curl -fsSL "$VM_LOGS_PLUGIN_URL" -o /tmp/vm-logs.zip \
  && unzip -q /tmp/vm-logs.zip -d /usr/share/grafana/plugins \
  && rm -f /tmp/vm-logs.zip \
  && find /usr/share/grafana/plugins -type f \( -name "*.so" -o -name "*_linux_*" -o -name "victoriametrics_logs_backend_plugin_*" \) -exec chmod +x {} \; \
  && chown -R 472:472 /usr/share/grafana/plugins \
  && apk del curl unzip
USER grafana

