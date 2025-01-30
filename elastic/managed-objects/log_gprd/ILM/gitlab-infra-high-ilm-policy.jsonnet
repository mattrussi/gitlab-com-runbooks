{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '7d',
            max_primary_shard_size: '50gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '2d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          allocate: {
            total_shards_per_node: 4,
          },
          set_priority: {
            priority: 50,
          },
        },
      },
      cold: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '7d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          set_priority: {
            priority: 0,
          },
          searchable_snapshot: {
            snapshot_repository: 'found_snapshots',

          },
        },
      },
      frozen: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '8d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          searchable_snapshot: {
            snapshot_repository: 'found_snapshots',

          },
        },
      },
      delete: {
        min_age: '9d',  //7d after rollover
        actions: {
          delete: {},
        },
      },
    },
  },
}
