{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '7d',  // try to pack a few days worth per index
            max_primary_shard_size: '20gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      cold: {
        min_age: '1d',
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
      delete: {
        min_age: '30d',  // keep static-objects-cache logs for 30d
        actions: {
          delete: {},
        },
      },
    },
  },
}
