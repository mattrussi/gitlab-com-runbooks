# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'

# %% Change working directory from the workspace root to the ipynb file location. Turn this addition off with the DataScience.changeDirOnImportExport setting
# ms-python.python added
# import os
# try:
# 	os.chdir(os.path.join(os.getcwd(), '../juypter-notebooks/2020-01-29-puma-analysis'))
# 	print(os.getcwd())
# except:
# 	pass

# %%
from IPython import get_ipython

# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import altair as alt

# %%
host_selection = '''
    CASE hostname
        WHEN 'web-02-sv-gprd' THEN 'puma'
        WHEN 'web-03-sv-gprd' THEN 'puma'
        WHEN 'web-04-sv-gprd' THEN 'puma'
        WHEN 'web-05-sv-gprd' THEN 'puma'
        WHEN 'web-06-sv-gprd' THEN 'puma'
        WHEN 'web-07-sv-gprd' THEN 'puma'
        WHEN 'web-08-sv-gprd' THEN 'puma'
        WHEN 'web-09-sv-gprd' THEN 'puma'

        WHEN 'web-12-sv-gprd' THEN 'unicorn'
        WHEN 'web-13-sv-gprd' THEN 'unicorn'
        WHEN 'web-14-sv-gprd' THEN 'unicorn'
        WHEN 'web-15-sv-gprd' THEN 'unicorn'
        WHEN 'web-16-sv-gprd' THEN 'unicorn'
        WHEN 'web-17-sv-gprd' THEN 'unicorn'
        WHEN 'web-18-sv-gprd' THEN 'unicorn'
        WHEN 'web-19-sv-gprd' THEN 'unicorn'

        WHEN 'api-02-sv-gprd' THEN 'puma'
        WHEN 'api-03-sv-gprd' THEN 'puma'
        WHEN 'api-04-sv-gprd' THEN 'puma'
        WHEN 'api-05-sv-gprd' THEN 'puma'
        WHEN 'api-06-sv-gprd' THEN 'puma'
        WHEN 'api-07-sv-gprd' THEN 'puma'
        WHEN 'api-08-sv-gprd' THEN 'puma'
        WHEN 'api-09-sv-gprd' THEN 'puma'

        WHEN 'api-12-sv-gprd' THEN 'unicorn'
        WHEN 'api-13-sv-gprd' THEN 'unicorn'
        WHEN 'api-14-sv-gprd' THEN 'unicorn'
        WHEN 'api-15-sv-gprd' THEN 'unicorn'
        WHEN 'api-16-sv-gprd' THEN 'unicorn'
        WHEN 'api-17-sv-gprd' THEN 'unicorn'
        WHEN 'api-18-sv-gprd' THEN 'unicorn'
        WHEN 'api-19-sv-gprd' THEN 'unicorn'

        ELSE 'other'
    END
'''

# %%
get_ipython().run_line_magic('matplotlib', 'inline')


# %%
get_ipython().run_line_magic('load_ext', 'google.cloud.bigquery')

# %%
get_ipython().run_cell_magic('bigquery', 'workhorse_healthcheck_durations_per_minute', '''
    SELECT date_min,
        hosttype,
        count,
        cast(percentiles[offset(5)] as FLOAT64) p50_duration_ms,
        cast(percentiles[offset(7)] as FLOAT64) p70_duration_ms,
        cast(percentiles[offset(9)] as FLOAT64) p90_duration_ms
    FROM (
        SELECT TIMESTAMP_TRUNC(a.timestamp, minute) as date_min,
            {host_selection} hosttype,
            count(*) count,
            APPROX_QUANTILES(CAST(duration_ms as float64), 10) percentiles
        FROM gcp_perf_analysis.workhorse_puma2020 a
        WHERE uri IN ('/-/liveness', '/-/readiness')
        GROUP BY 1,2
        ORDER BY 1
    )
  '''.format(host_selection=host_selection))

alt.Chart(workhorse_healthcheck_durations_per_minute).mark_line().encode(
    y=alt.Y('p70_duration_ms',
        scale=alt.Scale(zero=False)
    ),
    x='date_min:T',
    color=alt.Color('hosttype:N', scale=alt.Scale(scheme='category20c')),
    tooltip='hosttype:N'
).properties(
    width=1024, height=768
)

# %%
get_ipython().run_cell_magic('bigquery', 'workhorse_healthcheck_durations_overall', '''
    SELECT hosttype,
        count,
        cast(percentiles[offset(5)] as FLOAT64) p50_duration_ms,
        cast(percentiles[offset(6)] as FLOAT64) p60_duration_ms,
        cast(percentiles[offset(7)] as FLOAT64) p70_duration_ms,
        cast(percentiles[offset(9)] as FLOAT64) p90_duration_ms,
    FROM (
        SELECT
            {host_selection} hosttype,
            count(*) count,
            APPROX_QUANTILES(CAST(duration_ms as float64), 10) percentiles
        FROM gcp_perf_analysis.workhorse_puma2020 a
        WHERE uri IN ('/-/liveness', '/-/readiness')
        GROUP BY 1
        ORDER BY 1
    )
  '''.format(host_selection=host_selection))
workhorse_healthcheck_durations_overall


# %%
get_ipython().run_cell_magic('bigquery', 'workhorse_trace_durations_overall', '''
    SELECT hosttype,
        count,
        cast(percentiles[offset(5)] as FLOAT64) p50_duration_ms,
        cast(percentiles[offset(6)] as FLOAT64) p60_duration_ms,
        cast(percentiles[offset(7)] as FLOAT64) p70_duration_ms,
        cast(percentiles[offset(9)] as FLOAT64) p90_duration_ms
    FROM (
        SELECT
            {host_selection} hosttype,
            count(*) count,
            APPROX_QUANTILES(CAST(duration_ms as float64), 10 IGNORE NULLS) percentiles
        FROM gcp_perf_analysis.workhorse_puma2020 a
        WHERE uri like '/api/v4/jobs/%/trace'
        GROUP BY 1
        ORDER BY 1
    )
  '''.format(host_selection=host_selection))
workhorse_trace_durations_overall

# %%
get_ipython().run_cell_magic('bigquery', 'workhorse_trace_latencies', '''
    SELECT
         {host_selection} hosttype,
        TRUNC(CAST(duration_ms as float64), -2) latency_bucket,
        count(*) latency_bucket_count
    FROM gcp_perf_analysis.workhorse_puma2020 a
    WHERE CAST(duration_ms as float64) < 30000
      AND ({host_selection}) <> 'other'
    GROUP BY 1,2
    ORDER BY 2, 1
  '''.format(host_selection=host_selection))

# %%

alt.Chart(workhorse_trace_latencies).mark_line().encode(
    y=alt.Y('latency_bucket_count',
        scale=alt.Scale(type="log", base=10)
    ),
    x=alt.X('latency_bucket'),
    color=alt.Color('hosttype:N', scale=alt.Scale(scheme='category20c')),
).properties(
    width=1024, height=768
)

# %%
