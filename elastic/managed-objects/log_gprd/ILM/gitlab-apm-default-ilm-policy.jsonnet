{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '7d',
            max_primary_shard_size: '30gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      cold: {
        min_age: '2d',
        actions: {
          readonly: {},
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
      delete: {
        min_age: '7d',  //7d after rollover
        actions: {
          delete: {},
        },
      },
    },
  },
}
