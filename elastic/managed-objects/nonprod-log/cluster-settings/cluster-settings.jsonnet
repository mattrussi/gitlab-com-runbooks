{
  persistent: {
    // https://www.elastic.co/guide/en/elasticsearch/reference/current/disk-allocator.html
    // When reaching the storage low-watermark on a node, shards will be no longer be assigned to that node but if all nodes have reached the low-watermark, the cluster will stop storing any data. As per suggestion from Elastic (https://gitlab.com/gitlab-com/gl-infra/production/issues/616#note_124839760) we should use absolute byte values instead of percentages for setting the watermarks and, given the actual shard sizes, we should leave enough headroom for writing to shards, segment merging and node failure.
    // (I believe `gb` means GiB, but can't find a reference)
    'cluster.routing.allocation.disk.watermark.low': '85%',
    'cluster.routing.allocation.disk.watermark.high': '90%',
    'cluster.routing.allocation.disk.watermark.flood_stage': '95%',
    // https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/18066
    // https://www.elastic.co/guide/en/elasticsearch/reference/current/search-settings.html
    // Adjusting this from the 1024 (default) to 1536 to temporarily alleviate errors from full-text searches, until we can do a more proper assessment of our index mappings and usage to determine if/why so many fields are required.
    // Alternatively, this is dynamically adjusted in newer 8.x ES versions, and may be a moot point if/after we upgrade.
    'indices.query.bool.max_clause_count': '1536',
  },
}
