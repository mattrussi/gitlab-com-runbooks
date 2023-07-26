
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local type = 'code_suggestions';
local formatConfig = {
  selector: selectors.serializeHash({ env: '$environment', environment: '$environment', type: type }),
};

local bargaugePanel(
  title,
  description='',
  format='time_series',
  instant=true,
  legendFormat='__auto',
  orientation='horizontal',
  query='',
  reduceOptions={
    calcs: [
      'lastNotNull',
    ],
    fields: '',
    values: false,
  },
  thresholds={
    mode: 'absolute',
    steps: [
      {
        color: 'green',
        value: null,
      },
      {
        color: 'red',
        value: 80,
      },
    ],
  },
  unit='none',
  transformations=[],
) =
{
  description: description,
  fieldConfig: {
    values: false,
    defaults: {
      color: {
        mode: 'continuous-GrYlRd',
      },
      decimals: 1,
      thresholds: thresholds,
      unit: unit,
    },
  },
  options: {
    displayMode: 'basic',
    orientation: orientation,
    reduceOptions: reduceOptions,
    showUnfilled: true,
    valueMode: 'color',
  },
  targets: [
    promQuery.target(
      query, format=format, legendFormat=legendFormat, instant=instant
    )
  ],
  title: title,
  type: 'bargauge',
  transformations: transformations,
};

basic.dashboard(
  'Language',
  tags=['type:%s' % type, 'detail'],
  includeEnvironmentTemplate=true,
  includeStandardEnvironmentAnnotations=false,
)
.addPanels(
  layout.grid([
    basic.timeseries(
      stableId='request-language',
      title='Request Language / sec',
      query=|||
        sum by(lang, symbol) (
          rate(code_suggestions_prompt_language_total{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='__auto',
      format='ops',
      yAxisLabel='Requests per Second',
      decimals=1,
    ),
    bargaugePanel(
      'Usage by Language',
      query=|||
        topk(
          10,
          100 *
            sum by(lang) (
              increase(code_suggestions_prompt_language_total{%(selector)s,lang=~".+"}[$__range])
            )
            / on() group_left()
            sum (
              increase(code_suggestions_prompt_language_total{%(selector)s,lang=~".+"}[$__range])
            )
        )
      ||| % formatConfig,
      unit='percent',
    ),
    basic.timeseries(
      stableId='request-extension',
      title='Request Extension / sec',
      query=|||
        sum by(extension) (
          rate(code_suggestions_prompt_language_total{%(selector)s,extension=~".+"}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='__auto',
      format='ops',
      yAxisLabel='Requests per Second',
      decimals=1,
    ),
    bargaugePanel(
      'Usage by Extension',
      query=|||
        topk(
          10,
          100 *
            sum by(extension) (
              increase(code_suggestions_prompt_language_total{%(selector)s,extension=~".+"}[$__range])
            )
            / on() group_left()
            sum (
              increase(code_suggestions_prompt_language_total{%(selector)s,extension=~".+"}[$__range])
            )
        )
      ||| % formatConfig,
      unit='percent',
    ),
    basic.timeseries(
      stableId='request-symbol',
      title='Request Symbol / sec',
      query=|||
        sum by(lang) (
          rate(code_suggestions_prompt_symbols_total{%(selector)s,symbol="imports"}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='__auto',
      format='ops',
      yAxisLabel='Requests per Second',
      decimals=1,
    ),
    bargaugePanel(
      'Extensions with Unknown Language',
      query=|||
        topk(
          10,
          sum by(extension) (
            increase(code_suggestions_prompt_language_total{%(selector)s,lang="None",extension=~".+"}[$__range])
          )
        )
      ||| % formatConfig,
    ),
    basic.timeseries(
      stableId='acceptance-rate',
      title='Acceptance Rate / sec',
      query=|||
        100 *
          sum by(lang) (
            rate(code_suggestions_accepts_total{%(selector)s,lang=~".+"}[$__rate_interval])
          )
          / on(lang) group_left()
          sum by(lang) (
            rate(code_suggestions_requests_total{%(selector)s,lang=~".+"}[$__rate_interval]) > 0
          )
      ||| % formatConfig,
      legendFormat='{{lang}}',
      yAxisLabel='Acceptance Rates per Second',
      decimals=1,
    ),
    bargaugePanel(
      'Acceptance by Language',
      query=|||
        topk(
          10,
          100 *
            sum by(lang) (
              increase(code_suggestions_accepts_total{%(selector)s,lang=~".+"}[$__range])
            )
            / on(lang) group_left()
            sum by(lang) (
              increase(code_suggestions_requests_total{%(selector)s,lang=~".+"}[$__range]) > 0
            )
        )
      ||| % formatConfig,
      unit='percent',
    ),
  ], cols=2, rowHeight=10, startRow=0)
)
.trailer()
