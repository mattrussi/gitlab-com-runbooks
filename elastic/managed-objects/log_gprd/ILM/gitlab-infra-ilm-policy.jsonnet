{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '3d',
            max_size: '120gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        min_age: '1d',  // keep some data on hot nodes, otherwise disk usage is < 20%
        actions: {
          // skipping force merge for now for a performance optimisation test
          // forcemerge: {
          //   max_num_segments: 1,
          // },
          allocate: {
            require: {
              data: 'warm',
            },
          },
          set_priority: {
            priority: 50,
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
