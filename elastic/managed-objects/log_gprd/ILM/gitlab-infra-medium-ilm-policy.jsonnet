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
      warm: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '2d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          // skipping force merge for now for a performance optimisation test
          // forcemerge: {
          //   max_num_segments: 1,
          // },
          allocate: {
            total_shards_per_node: 3,
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
          allocate: {
            number_of_replicas: 0,
          },
          searchable_snapshot: {
            snapshot_repository: 'found-snapshots',

          },
        },
      },
      frozen: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '8d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          searchable_snapshot: {
            snapshot_repository: 'found-snapshots',

          },
        },
      },
      delete: {
        min_age: '11d',  //7d after rollover
        actions: {
          delete: {},
        },
      },
    },
  },
}
