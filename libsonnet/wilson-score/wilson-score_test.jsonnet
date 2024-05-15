local underTest = import './wilson-score.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local strings = import 'utils/strings.libsonnet';

test.suite({
  testBasicLower: {
    actual: strings.chomp(underTest.lower(scoreRate='score', totalRate='total', windowInSeconds=3600, confidence='95%')),
    expect: strings.chomp(|||
      (
        (
          (score / total)
          +
          3.841459 / (2 * (total * 3600))
        )
        -
        1.959964
        *
        sqrt(
          (
            (score / total) * (1 - (score / total))
            +
            3.841459 / (4 * (total * 3600))
          )
          /
          (total * 3600)
        )
      )
      /
      (1 + 3.841459 / (total * 3600))
    |||),
  },
  testBasicUpper: {
    actual: strings.chomp(underTest.upper(scoreRate='score', totalRate='total', windowInSeconds=3600, confidence='95%')),
    expect: strings.chomp(|||
      (
        (
          (score / total)
          +
          3.841459 / (2 * (total * 3600))
        )
        +
        1.959964
        *
        sqrt(
          (
            (score / total) * (1 - (score / total))
            +
            3.841459 / (4 * (total * 3600))
          )
          /
          (total * 3600)
        )
      )
      /
      (1 + 3.841459 / (total * 3600))
    |||),
  },
  testApdexUpper: {
    actual: strings.chomp(underTest.upper(scoreRate='gitlab_component_apdex:success:rate_1h', totalRate='gitlab_component_apdex:weight:score_1h', windowInSeconds=3600, confidence='95%')),
    expect: strings.chomp(|||
      (
        (
          (gitlab_component_apdex:success:rate_1h / gitlab_component_apdex:weight:score_1h)
          +
          3.841459 / (2 * (gitlab_component_apdex:weight:score_1h * 3600))
        )
        +
        1.959964
        *
        sqrt(
          (
            (gitlab_component_apdex:success:rate_1h / gitlab_component_apdex:weight:score_1h) * (1 - (gitlab_component_apdex:success:rate_1h / gitlab_component_apdex:weight:score_1h))
            +
            3.841459 / (4 * (gitlab_component_apdex:weight:score_1h * 3600))
          )
          /
          (gitlab_component_apdex:weight:score_1h * 3600)
        )
      )
      /
      (1 + 3.841459 / (gitlab_component_apdex:weight:score_1h * 3600))
    |||),
  },
  testErrorLower: {
    actual: strings.chomp(underTest.lower(scoreRate='gitlab_component_errors:rate_1h', totalRate='gitlab_component_ops:rate_1h', windowInSeconds=3600, confidence='95%')),
    expect: strings.chomp(|||
      (
        (
          (gitlab_component_errors:rate_1h / gitlab_component_ops:rate_1h)
          +
          3.841459 / (2 * (gitlab_component_ops:rate_1h * 3600))
        )
        -
        1.959964
        *
        sqrt(
          (
            (gitlab_component_errors:rate_1h / gitlab_component_ops:rate_1h) * (1 - (gitlab_component_errors:rate_1h / gitlab_component_ops:rate_1h))
            +
            3.841459 / (4 * (gitlab_component_ops:rate_1h * 3600))
          )
          /
          (gitlab_component_ops:rate_1h * 3600)
        )
      )
      /
      (1 + 3.841459 / (gitlab_component_ops:rate_1h * 3600))
    |||),
  },
})
