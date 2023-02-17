## Steps to check

1. Login to server - `prometheus.gitlab.com` or `prometheus-2.gitlab.com`. Check service with `sv status prometheus`. If it is `run` for more than `0s`. Then it is ok.
1. If it is `down` state, then check logs in `/var/log/prometheus/prometheus/current`. Actions can be taken after logs investigating. Usually it is configuration error or IO/space problems.

## How to work with Prometheus

1. Check configuration - `/opt/prometheus/prometheus/promtool check config /opt/prometheus/prometheus/prometheus.yml`.
It should check prometheus configuration file and alerts being used. Please always run this check before restarting prometheus service.
1. Reload configuration - `sudo sv reload prometheus`.
1. Restart service - `sudo sv restart prometheus` after checking configuration.

## Many Restarts

### thanos-compact

Sometimes the chunks of data in GCS that thanos-compact is working on can be corrupted in ways that cause thanos-compact to crash hard and restart, leading to a crashloop and the PrometheusManyRestarts alert.

One such issue resulted in this log on `/var/log/prometheus/thanos-compact/current`:
It may be the case that this file does not exist. In that case you can view logs via the systemd journal: `sudo journalctl -u thanos-compact.service`

```
{"caller":"main.go:215","err":"error executing compaction: compaction failed: compaction failed for group 0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}: compact blocks [/opt/prometheus/thanos/compact-data/compact/0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}/01DS5AQG40F0NWX3GP57KR1XGF /opt/prometheus/thanos/compact-data/compact/0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}/01DS5HK7C0HR5WNS9KHEXV0J68 /opt/prometheus/thanos/compact-data/compact/0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}/01DS5REYM1E1J0X3GTVZ9NNJ68 /opt/prometheus/thanos/compact-data/compact/0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}/01DS5ZANVZ9N7A14EKPHPZ70MM]: write compaction: iterate compaction set: chunk 45 not found: invalid encoding \"\u003cunknown\u003e\"","level":"error","msg":"running command failed","ts":"2019-11-11T04:12:56.374664759Z"}
```

The key identifier is `compaction failed for group` and `pre compaction overlap check: overlaps found while gathering blocks`.
The rest of the message is a bit hard to read, but the interesting facts are

1. the identifier of the source: "0@{env=\"gprd\",monitor=\"app\",provider=\"gcp\",region=\"us-east\",replica=\"02\"}", which says that this came from prometheus-app-02-inf-gprd ('env', 'monitor', and 'replica' are the relevant parts).  This is possibly only tangentially interesting, for locating the source of the corruption
1. The chunk names.  In the above example, these are 01DS5AQG40F0NWX3GP57KR1XGF, 01DS5HK7C0HR5WNS9KHEXV0J68, 01DS5REYM1E1J0X3GTVZ9NNJ68 , and 01DS5ZANVZ9N7A14EKPHPZ70MM

In this situation there does not appear to be any reasonable way to recover the data in those chunks, and we should count the data as lost.  Having extracted the chunk names from the logs, the following will delete them:

```bash
for i in $CHUNK1 $CHUNK2 $CHUNK3 $CHUNK4; do gsutil -m rm -r gs://gitlab-$ENV-prometheus/$i/; done
```

(NB: the trailing / after $i prevents accidents if $i is accidentally empty)
Adjust the `$ENV` component of the bucket name based on which environment you're working on.
You may have to do this multiple times as thanos-compact finds new corrupted chunks; keep a tail on the logs until the restarts cease and all corrupted blocks are removed.

#### Example: overlap in blocks

1. Get overlaping blocks by checking mint and maxt of overlapping blocks and determining, which one has larger set of metrics e.g.

    ```
    {"caller":"main.go:161","err":"group 3600000@1852658181705106333: pre compaction overlap check: overlaps found while gathering blocks. [mint: 1600300800000, maxt: 1601337600000, range: 288h0m0s, blocks: 2]: <ulid: 01GRR0B5T56JH0199S5RYW448M, mint: 1600300800000, maxt: 1601510400000, range: 336h0m0s>, <ulid: 01GMR2RSSHRVJJCK14CV6CQ1WV, mint: 1600300800000, maxt: 1601337600000, range: 288h0m0s>\ncompaction\nmain.runCompact.func7\n\t/app/cmd/thanos/compact.go:423\nmain.runCompact.func8.1\n\t/app/cmd/thanos/compact.go:477\ngithub.com/thanos-io/thanos/pkg/runutil.Repeat\n\t/app/pkg/runutil/runutil.go:74\nmain.runCompact.func8\n\t/app/cmd/thanos/compact.go:476\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.1.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1594\ncritical error detected\nmain.runCompact.func8.1\n\t/app/cmd/thanos/compact.go:491\ngithub.com/thanos-io/thanos/pkg/runutil.Repeat\n\t/app/pkg/runutil/runutil.go:74\nmain.runCompact.func8\n\t/app/cmd/thanos/compact.go:476\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.1.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1594\ncompact command failed\nmain.main\n\t/app/cmd/thanos/main.go:161\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:250\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1594","level":"error","ts":"2023-02-17T00:45:58.257320608Z"}
    ```
    In this case, both blocks have same mint `1600300800000` but block `01GRR0B5T56JH0199S5RYW448M` has larger maxt (`1601510400000`), meaning that it encompasses metrics from time range of the other block `01GMR2RSSHRVJJCK14CV6CQ1WV` and therefore `01GMR2RSSHRVJJCK14CV6CQ1WV` can be deleted. Use batch converter of epoch timestamps for comparing timestamps: https://epochconverter.com/batch

2. Delete the blocks

    ```shell
    for i in 01GRD8X5H5SVGEWMCMVNC2CYC3 01GRDB3QJZHV8JW7XP6TM04BVJ 01GRFM82QG7ZESZHREP4V5VNBX 01GRJVN89FG85550QQ0GXXMANT 01GRCCGKVXK72T94Z5PSBTWZVC 01GRCQNJ4YKSG4Y114EBNC55C1 01GRCZJ9DR4MR641X29ARYN09E 01GRG4VN3D2YNACR59V34A5T3F 01GRC8W59VYWFDX9D6VWWQBQ5N 01GRD4Q6HBMB0TYQ0CANB3YM3J 01GREJH27NQCNHV5654B1TWQM9; do gsutil -m rm -r gs://gitlab-gprd-prometheus/$i/; done
    ```
