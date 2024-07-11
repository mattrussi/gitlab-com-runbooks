## Description

The `generate-mixin.sh` script is designed to generate Prometheus configurations (alerts, rules, dashboards) using `mixtool` based on the provided `mixin.libsonnet` file. The outputs are stored in directories under `generated/{MIXIN_DIR}`.

## Usage

```sh
./generate-mixin.sh {alerts|rules|dashboards|all} MIXIN_DIR
```
