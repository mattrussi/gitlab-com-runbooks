local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;

local monthlyReleaseStatusQuery = 'max_over_time(delivery_release_monthly_status[30d])';

local monthlyReleaseInfoTextPanel =
  basic.text(
    title='',
    content=|||
      # Upcoming Monthly Release

      The Delivery group releases a new package version for self-managed users on the third Thursday of every month.

      This release is a semver versioned package containing changes from many successful deployments on GitLab.com.

      The following panels contain information about the upcoming monthly release.

      [Monthly release schedule](https://about.gitlab.com/releases/)

      [Overview of the process](https://handbook.gitlab.com/handbook/engineering/deployments-and-releases/)

      [How can I determine if my MR will make it into the monthly release](https://handbook.gitlab.com/handbook/engineering/releases/#how-can-i-determine-if-my-merge-request-will-make-it-into-the-monthly-release)

      For inquiries about the monthly release, please ask in the [`#releases` slack channel](https://gitlab.enterprise.slack.com/archives/C0XM5UU6B).
    |||,
  );

local monthlyReleaseStatusTextPanel =
  basic.text(
    title='',
    content=|||
      # Release Status

      The right-most panel in the row below shows the current status of the upcoming monthly release.
      The following are the different statuses, and what each signify for engineers:

      * Open: Engineers can create MRs, and any commit that reached production is expected to be released with the next monthly release.
      * Announced: Guaranteed SHA has been announced in `#releases` slack channel. Signals that the RC tagging date is getting closer.
      * RC Tagged: The stable branch has been created, and the release candidate has been tagged. No more commits will be included in the release.
    |||,
  );

local monthlyReleaseVersionStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Release Version',
    description='This is the current monthly release version that will be published on the next third Thursday of the month.',
    query=monthlyReleaseStatusQuery,
    colorMode='thresholds',
    fields='/^version$/',
    format='table',
    graphMode='area',
    instant=false,
    color=[
      { color: 'white', value: null },
    ],
    transformations=[
      {
        id: 'groupBy',
        options: {
          fields: {
            Value: {
              aggregations: [],
              operation: 'groupby',
            },
            release_date: {
              aggregations: [],
              operation: 'groupby',
            },
            version: {
              aggregations: [],
              operation: 'groupby',
            },
          },
        },
      },
      {
        id: 'sortBy',
        options: {
          fields: {},
          sort: [
            {
              field: 'version',
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'last',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

local monthlyReleaseDateStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Release Date',
    description='This is the release date for the next monthly release.',
    query=monthlyReleaseStatusQuery,
    colorMode='thresholds',
    fields='/^release_date$/',
    format='table',
    graphMode='area',
    instant=false,
    color=[
      { color: 'white', value: null },
    ],
    transformations=[
      {
        id: 'groupBy',
        options: {
          fields: {
            Value: {
              aggregations: [],
              operation: 'groupby',
            },
            release_date: {
              aggregations: [],
              operation: 'groupby',
            },
            version: {
              aggregations: [],
              operation: 'groupby',
            },
          },
        },
      },
      {
        id: 'sortBy',
        options: {
          fields: {},
          sort: [
            {
              field: 'version',
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'last',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

local monthlyReleaseStatusStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Current Release Status',
    description='Current status of the monthly release. More information about the statuses in the text panel above.',
    query=monthlyReleaseStatusQuery,
    colorMode='value',
    format='table',
    graphMode='area',
    instant=false,
    mappings=[
      {
        id: 0,
        type: 1,
        value: '1',
        text: 'Open',
      },
      {
        id: 1,
        type: 1,
        value: '2',
        text: 'Announced',
      },
      {
        id: 2,
        type: 1,
        value: '3',
        text: 'RC Tagged',
      },
    ],
    color=[
      { color: 'green', value: 1 },
      { color: 'yellow', value: 2 },
      { color: 'red', value: 3 },
    ],
    transformations=[
      {
        id: 'groupBy',
        options: {
          fields: {
            Value: {
              aggregations: [],
              operation: 'groupby',
            },
            release_date: {
              aggregations: [],
              operation: 'groupby',
            },
            version: {
              aggregations: [],
              operation: 'groupby',
            },
          },
        },
      },
      {
        id: 'sortBy',
        options: {
          fields: {},
          sort: [
            {
              field: 'version',
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'last',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

basic.dashboard(
  'Release Information',
  tags=['release'],
  editable=true,
  time_from='now-3d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addPanels(
  [
    row.new(title='Monthly Release Information') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
  ] +
  layout.grid(
    [
      monthlyReleaseInfoTextPanel,
      monthlyReleaseStatusTextPanel,
    ], cols=2, startRow=1
  )
  +
  layout.grid(
    [
      monthlyReleaseVersionStatPanel,
      monthlyReleaseDateStatPanel,
      monthlyReleaseStatusStatPanel,
    ], cols=3, startRow=2
  )
)

.trailer()
