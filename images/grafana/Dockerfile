FROM grafana/grafana:11.2.0

# Preload plugins for offline environments.
# Add additional plugins to the grafana-cli command as needed.
RUN grafana-cli --pluginsDir "/var/lib/grafana/plugins" plugins install victoriametrics-logs-datasource

