# HTTP Router Worker Logs

**Table of Contents**

[TOC]

# Logging in HTTP Router

The [http-router](https://gitlab.com/gitlab-org/cells/http-router) leverages [Cloudflare Workers](https://developers.cloudflare.com/workers/) for its operations. For log persistence and analysis, we utilize a combination of [Worker Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/) and [Worker Logpush](https://developers.cloudflare.com/workers/observability/logs/logpush/) services.

## Worker Logs Overview

Worker Logs is a managed service provided by Cloudflare that handles log retention and storage while providing an intuitive interface for log consumption and analysis.

### Available Log Interfaces

Two primary interfaces are available for log analysis:

- [`Live Logs`](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/workers/services/live-logs/production-gitlab-com-cells-http-router/production): Real-time log monitoring
- [`Worker Logs`](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/workers/services/view/production-gitlab-com-cells-http-router/production/observability/logs): Historical log analysis

### Configuration Details

Log configuration is managed through the [`wrangler.toml`](https://gitlab.com/gitlab-org/cells/http-router/-/blob/c0bbfaae75be7d534713564aa29866af78705dd1/wrangler.toml#L80) configuration file.

To optimize costs while maintaining meaningful insights, we leverage head-based sampling with a [1% sampling rate](https://gitlab.com/gitlab-org/cells/http-router/-/blob/c0bbfaae75be7d534713564aa29866af78705dd1/wrangler.toml#L82) as described in the configuration file.

## Worker Logpush

Cloudflare Worker Logpush is a feature that allows us to export detailed logs from the Cloudflare Workers to a GCS bucket and analyze the logs. We primarily use it for error tracking and don't sample the request.

### Querying Logs through Big Query

TBD - Docs will be added after, we complete the [Persist Error logs from worker issue](https://gitlab.com/gitlab-org/cells/http-router/-/issues/94)

### Configuration

TBD - Docs will be added after, we complete the [Persist Error logs from worker issue](https://gitlab.com/gitlab-org/cells/http-router/-/issues/94)
