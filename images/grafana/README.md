# Grafana offline image

Build a Grafana image with preloaded plugins for offline/air-gapped environments.

## Build

```
docker build -t grafascope/grafanaplg:11.2.0-with-vl .
```

## Use with the chart

Set the Grafana image in `grafascope/values.yaml`:

```
grafana:
  image:
    repository: grafascope/grafanaplg
    tag: 11.2.0-with-vl
  pluginsInstall: false
```

This disables `GF_INSTALL_PLUGINS` (which requires internet) and relies on the
preloaded plugins baked into the image.

