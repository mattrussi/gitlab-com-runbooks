# Deleting series over a given interval from thanos

It may happen that some bad data lands in prometheus and subsequently thanos.

Since we rely heavily on monitoring data for all kinds of processes, including availability reporting, error budgets for stage groups, capacity planning, we may have an interest in purging that bad data.

This can be done in 3 steps:

1. Find the blocks containing the bad data.
1. Configure the series and intervals to be deleted.
1. Run `thanos tools bucket rewrite` against the blocks in the bucket.

## 1. Find the blocks containing the bad data

### Bucket structure

Prometheus and thanos store data in blocks. These blocks are uploaded to a GCS bucket. There is one GCS bucket per environment:

- `gitlab-ops-prometheus`
- `gitlab-gprd-prometheus`
- `gitlab-gstg-prometheus`
- `gitlab-pre-prometheus`

Sample structure:

```
➜  ~ gsutil ls gs://gitlab-gprd-prometheus | head

gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/
gs://gitlab-gprd-prometheus/01DNVPVHCQSANGM8JS109EDVV4/
gs://gitlab-gprd-prometheus/01DNVQ6E65EPEGD2WE3FVM2R46/

➜  ~ gsutil ls -r gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05
gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/:
gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/index
gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/meta.json

gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/chunks/:
gs://gitlab-gprd-prometheus/01DNVPQX917XY80CZFQBG4BQ05/chunks/000001
```

### Identifying blocks

It is possible to list all blocks and their respective labels with the `thanos tools bucket inspect` command. Note that for large buckets (e.g. `gprd`) this can take on the order of 5 minutes to process all blocks.

Sample:

```
➜  ~ cat objstore.yml
type: GCS
config:
  bucket: gitlab-ops-prometheus

➜  ~ thanos tools bucket inspect --objstore.config-file=objstore.yml
```

This output is not very machine friendly though. So an alternative method to get the same information is to query the bucket directly. This also enables filtering the blocks for the time range you care about.

<!-- markdownlint-disable MD010 -->

```
➜  ~ echo "$(gdate --date='2022-09-15 22:00:00 UTC' '+%s')000"
1663279200000

➜  ~ echo "$(gdate --date='2022-09-16 01:36:00 UTC' '+%s')000"
1663292160000

➜  ~ gsutil ls gs://gitlab-ops-prometheus | parallel -X -n 10 "gsutil cat {}meta.json | jq -cr '[.ulid, .minTime, .maxTime, (.minTime/1000|strftime(\"%Y-%m-%d %H:%M:%S\")), (.maxTime/1000|strftime(\"%Y-%m-%d %H:%M:%S\")), .thanos.source, .thanos.downsample.resolution, (.thanos.labels|to_entries|map(.key + \"=\" + .value)|join(\",\"))]|@tsv'" > gitlab-ops-prometheus.blocks.out

➜  ~ sort -o gitlab-ops-prometheus.blocks.out gitlab-ops-prometheus.blocks.out

➜  ~ cat gitlab-ops-prometheus.blocks.out | awk '$2 <= 1663279200000 && $3 >= 1663292160000' | grep monitor=global

01GD4Z87286SVT6V06FVDNCTV0	1663200000200	1663372800000	2022-09-15 00:00:00	2022-09-17 00:00:00	compactor	0	monitor=global,replica=01
01GD4ZEEGZ074E4FA84YT877KF	1663200000200	1663372800000	2022-09-15 00:00:00	2022-09-17 00:00:00	compactor	0	monitor=global,replica=02
01GD4ZN8Q4KSJ75HTBJ0VNY7RB	1663200000200	1663372800000	2022-09-15 00:00:00	2022-09-17 00:00:00	compactor	300000	monitor=global,replica=01
01GD4ZXHHWMGXTGPE8CSKF1F2F	1663200000200	1663372800000	2022-09-15 00:00:00	2022-09-17 00:00:00	compactor	300000	monitor=global,replica=02
```

<!-- markdownlint-enable MD010 -->

This will give you block IDs (ULID), timestamps, and block-level labels.

### Correlating with series

You can use the block-level labels to figure out which blocks contain the series you want to delete.

Say we want to delete a specific interval from this series:

```
gitlab_service_ops:rate_5m{env="gprd",type="git"}
```

The instant query from [thanos.gitlab.net](https://thanos.gitlab.net/) tells us that all of the labels associated with this series are:

```
gitlab_service_ops:rate_5m{env="gprd", environment="gprd", monitor="global", stage="cny", tier="sv", type="git"}
1049.6081058725845
gitlab_service_ops:rate_5m{env="gprd", environment="gprd", monitor="global", stage="main", tier="sv", type="git"}
21400.51322406771
```

And indeed `monitor="global"` is one of the block labels above. So by combining these two pieces of information, we can now identify the block IDs we care about.

In our case, they are:

```
01GD4Z87286SVT6V06FVDNCTV0
01GD4ZEEGZ074E4FA84YT877KF
01GD4ZN8Q4KSJ75HTBJ0VNY7RB
01GD4ZXHHWMGXTGPE8CSKF1F2F
```

## 2. Configure the series and intervals to be deleted

Now that we have the blocks, we need to prepare the config file describing what needs to be deleted.

That can be done by adapting [`metrics-catalog/deletion-config-for-aggregation-sets.jsonnet`](https://gitlab.com/gitlab-com/runbooks/-/merge_requests/5001), and substituting or otherwise generating a config file that `thanos tools bucket rewrite` expects.

The format is documented [here](https://thanos.io/tip/operating/modify-objstore-data.md/), but this documentation omits [the `intervals` key](https://github.com/thanos-io/thanos/blob/043c5bfcc2464d3ae7af82a1428f6e0d6510f020/pkg/block/metadata/meta.go#L116) that allows a time range to be specified.

The `thanos.rewrite.to-delete.yml` file should look something like this:

```
- intervals:
    - maxt: 1663292160000
      mint: 1663279200000
  matchers: '{__name__="gitlab_component_apdex:ratio"}'
- intervals:
    - maxt: 1663292160000
      mint: 1663279200000
  matchers: '{__name__="gitlab_component_errors:rate"}'

...
```

Matchers is a label selector, `mint` and `maxt` are millisecond-precision unix timestamps.

## 3. Run `thanos tools bucket rewrite` against the blocks in the bucket

Finally, the blocks can actually be rewritten.

This can be done by invoking `thanos tools bucket rewrite` as follows for a dry-run:

```
➜  ~ thanos tools bucket rewrite --objstore.config-file=objstore.yml --rewrite.to-delete-config-file=thanos.rewrite.to-delete.yml --id=01GD4Z87286SVT6V06FVDNCTV0 --rewrite.add-change-log
```

And if that looks reasonable, perform the actual rewrite:

```
➜  ~ thanos tools bucket rewrite --objstore.config-file=objstore.yml --rewrite.to-delete-config-file=thanos.rewrite.to-delete.yml --id=01GD4Z87286SVT6V06FVDNCTV0 --rewrite.add-change-log --no-dry-run
```

This will write out a new block and mark the old one for deletion.

## Local testing

Note that it is possible to test these operations locally before applying them on the live bucket. This can be done by copying the block files down from the bucket, applying the rewrite locally, and pointing a local prometheus at them.

Download block:

```
echo 01GD4Z87286SVT6V06FVDNCTV0 | parallel --ungroup 'mkdir -p gitlab-ops-prometheus/{} && gsutil -m rsync -r gs://gitlab-ops-prometheus/{} gitlab-ops-prometheus/{}'
```

Perform rewrite against local filesystem:

```
➜  ~ cat objstore.yml

type: FILESYSTEM
config:
  directory: gitlab-ops-prometheus

➜  ~ thanos tools bucket rewrite --objstore.config-file=objstore.yml --rewrite.to-delete-config-file=thanos.rewrite.to-delete.yml --id=01GD4Z87286SVT6V06FVDNCTV0 --rewrite.add-change-log --no-dry-run

➜  ~ ls -lah gitlab-ops-prometheus
```

Note that prometheus will not start if there are overlapping blocks. While thanos marks the old block for deletion, it does not actively delete it. Because of this, the old block needs to be renamed or removed after the rewrite operation.

```
➜  ~ mv gitlab-ops-prometheus/01GD4Z87286SVT6V06FVDNCTV0 gitlab-ops-prometheus/01GD4Z87286SVT6V06FVDNCTV0.bak
```

Start local prometheus:

```
➜  ~ prometheus --storage.tsdb.path gitlab-ops-prometheus
➜  ~ open http://localhost:9090
```
