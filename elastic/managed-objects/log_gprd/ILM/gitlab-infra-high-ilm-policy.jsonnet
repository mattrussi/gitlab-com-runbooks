{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '7d',
            max_primary_shard_size: '50gb',
          },
          forcemerge: {
            max_num_segments: 1,
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      cold: {
        min_age: '36h',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          set_priority: {
            priority: 50,
          },
          allocate: {
            number_of_replicas: 0,
          },
          searchable_snapshot: {
            force_merge_index: true,
            snapshot_repository: 'found-snapshots',

          },
        },
      },
      frozen: {
        min_age: '4d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          searchable_snapshot: {
            force_merge_index: true,
            snapshot_repository: 'found-snapshots',

          },
        },
      },
      delete: {
        min_age: '7d', 
        actions: {
          delete: {},
        },
      },
    },
  },
}
