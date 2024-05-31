local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;

// Monthly Release Information panels

local monthlyReleaseStatusQuery = 'max_over_time(delivery_release_monthly_status[30d])';

local monthlyReleaseInfoTextPanel =
  basic.text(
    title='',
    content=|||
      # Active Monthly Release

      GitLab releases a new self-managed release on the third Thursday of every month.

      This release is a semver versioned package containing changes from many successful deployments on GitLab.com.

      The following panels contain information about the active monthly release.

      Links:
      - [Monthly release schedule](https://about.gitlab.com/releases/)
      - [Overview of the process](https://handbook.gitlab.com/handbook/engineering/deployments-and-releases/)
      - [How can I determine if my MR will make it into the monthly release](https://handbook.gitlab.com/handbook/engineering/releases/#how-can-i-determine-if-my-merge-request-will-make-it-into-the-monthly-release)

      For inquiries about the monthly release, please ask in the [`#releases` slack channel](https://gitlab.enterprise.slack.com/archives/C0XM5UU6B).
    |||,
  );

local monthlyReleaseStatusTextPanel =
  basic.text(
    title='',
    content=|||
      # Release Status

      The panel below shows the current status of the active monthly release.

      The following are what the statuses signify for engineers:

      * Open: Engineers can create MRs, and any commit that reached production is expected to be released with the active monthly release.
      * Announced: Guaranteed SHA has been announced in `#releases` slack channel. Signals that the RC tagging date is getting closer. Further commits are not guaranteed to be included.
      * RC Tagged: The stable branch has been created, and the release candidate has been tagged. No more commits will be included in the release.
    |||,
  );

local monthlyReleaseVersionStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Release Version',
    description='This is the active monthly release version that will be published on the next third Thursday of the month.',
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
            Time: {
              aggregations: [
                'min',
              ],
              operation: 'aggregate',
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
              field: 'Time (min)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
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
    description='This is the release date for the active monthly release.',
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
            Time: {
              aggregations: [
                'min',
              ],
              operation: 'aggregate',
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
              field: 'Time (min)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
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
    query='delivery_release_monthly_status',
    colorMode='value',
    fields='/^Value$/',
    format='table',
    graphMode='area',
    instant=false,
    noValue='Open',
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
      { color: 'green', value: null },
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
            Time: {
              aggregations: [
                'max',
              ],
              operation: 'aggregate',
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
              field: 'Time (max)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

// Patch Release Information panels

local patchReleaseStatusQuery = 'max_over_time(delivery_release_patch_status[30d])';

local patchReleaseInfoTextPanel =
  basic.text(
    title='',
    content=|||
      # Active Patch Release

      Patch releases include bug and security fixes based on the [Maintenance Policy](https://docs.gitlab.com/ee/policy/maintenance.html), they are scheduled twice a month on the second and fourth Wednesdays.

      The following panels contain information about the active patch release.

      Links:
      - [Overview of the Patch Release Process](https://handbook.gitlab.com/handbook/engineering/releases/#patch-releases-overview)
      - [Maintenance Policy](https://docs.gitlab.com/ee/policy/maintenance.html)
      - [Process to include bug fixes](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md)
      - [Process to include security fixes](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/engineer.md)
      - [Backporting to older releases](https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases)
      - [Security Tracking Issue](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&label_name%5B%5D=upcoming%20security%20release&first_page_size=20)

      For inquiries about the patch release, please ask in the [`#releases` slack channel](https://gitlab.enterprise.slack.com/archives/C0XM5UU6B).
    |||,
  );

local patchReleaseStatusTextPanel =
  basic.text(
    title='',
    content=|||
      # Release Status

      The panel below shows the current status of the active patch release.

      The following are what the statuses signify for engineers:

      * Open: Bug fixes and MRs associated with security issues labelled `security-target` are expected to be included in the next patch release.
      * Warning: Signals that teams should get bug and security fixes ready to merge.
      * Closed: Default branch MRs have been merged, no further bug or security fixes will be included.
    |||,
  );

local patchReleaseVersionStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Release Versions',
    description='These are the active patch release versions (stable version + 2 backport versions) that will be published.',
    query=patchReleaseStatusQuery,
    colorMode='thresholds',
    fields='/^versions$/',
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
            versions: {
              aggregations: [],
              operation: 'groupby',
            },
            Time: {
              aggregations: [
                'min',
              ],
              operation: 'aggregate',
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
              field: 'Time (min)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

local patchReleaseDateStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Expected Release Date',
    description="This is the best-effort release date for the active patch release, and might be subject to change. A good place to confirm is the tracking issue's due date.",
    query=patchReleaseStatusQuery,
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
            versions: {
              aggregations: [],
              operation: 'groupby',
            },
            Time: {
              aggregations: [
                'min',
              ],
              operation: 'aggregate',
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
              field: 'Time (min)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
          ],
          includeTimeField: false,
          mode: 'reduceFields',
        },
      },
    ],
  );

local patchReleaseStatusStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Current Release Status',
    description='Current status of the patch release. More information about the statuses in the text panel above.',
    query='delivery_release_patch_status',
    colorMode='value',
    fields='/^Value$/',
    format='table',
    graphMode='area',
    instant=false,
    noValue='Open',
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
        text: 'Warning',
      },
      {
        id: 2,
        type: 1,
        value: '3',
        text: 'Closed',
      },
    ],
    color=[
      { color: 'green', value: null },
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
            versions: {
              aggregations: [],
              operation: 'groupby',
            },
            Time: {
              aggregations: [
                'max',
              ],
              operation: 'aggregate',
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
              field: 'Time (max)',
              desc: true,
            },
          ],
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'first',
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
  time_from='now-22d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addPanel(
  row.new(title='Monthly Release Information'),
  gridPos={ x: 0, y: 0, w: 24, h: 1 },
)
.addPanel(
  monthlyReleaseInfoTextPanel, gridPos={ x: 0, y: 1, w: 16, h: 10 }
)
.addPanel(
  monthlyReleaseStatusTextPanel, gridPos={ x: 16, y: 1, w: 8, h: 10 }
)
.addPanel(
  monthlyReleaseVersionStatPanel, gridPos={ x: 0, y: 11, w: 8, h: 8 }
)
.addPanel(
  monthlyReleaseDateStatPanel, gridPos={ x: 8, y: 11, w: 8, h: 8 }
)
.addPanel(
  monthlyReleaseStatusStatPanel, gridPos={ x: 16, y: 11, w: 8, h: 8 }
)
.addPanel(
  row.new(title='Patch Release Information'),
  gridPos={ x: 0, y: 19, w: 24, h: 1 },
)
.addPanel(
  patchReleaseInfoTextPanel, gridPos={ x: 0, y: 20, w: 16, h: 11 }
)
.addPanel(
  patchReleaseStatusTextPanel, gridPos={ x: 16, y: 20, w: 8, h: 11 }
)
.addPanel(
  patchReleaseVersionStatPanel, gridPos={ x: 0, y: 31, w: 8, h: 8 }
)
.addPanel(
  patchReleaseDateStatPanel, gridPos={ x: 8, y: 31, w: 8, h: 8 }
)
.addPanel(
  patchReleaseStatusStatPanel, gridPos={ x: 16, y: 31, w: 8, h: 8 }
)
.trailer()
