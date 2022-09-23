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
      warm: {
        min_age: '2d',
        actions: {
          readonly: {},
          set_priority: {
            priority: 50,
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
