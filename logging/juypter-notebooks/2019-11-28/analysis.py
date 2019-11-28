# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %% Change working directory from the workspace root to the ipynb file location. Turn this addition off with the DataScience.changeDirOnImportExport setting
# ms-python.python added
import os
try:
	os.chdir(os.path.join(os.getcwd(), '../juypter-notebooks/2019-11-28'))
	print(os.getcwd())
except:
	pass
# %%
from IPython import get_ipython

# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import altair as alt


# %%
get_ipython().run_line_magic('matplotlib', 'inline')


# %%
get_ipython().run_line_magic('load_ext', 'google.cloud.bigquery')

# %%
get_ipython().run_cell_magic('bigquery', 'request_queue_durations ', '''
    SELECT date_hour,
        count,
        cast(percentiles[offset(75)] as FLOAT64) p75_queue_duration ,
        cast(percentiles[offset(95)] as FLOAT64) p95_queue_duration
    FROM (
        SELECT TIMESTAMP_TRUNC(a.timestamp, hour) as date_hour,
            count(*) count,
            APPROX_QUANTILES(queue_duration, 100) percentiles
        FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
        GROUP BY 1
        ORDER BY 1
    )
  ''')


# %%
alt.Chart(request_queue_durations).mark_line().encode(
    y=alt.Y('p95_queue_duration', scale=alt.Scale(domain=[1, 7500], clamp=True)),
    x='date_hour:T'
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'workhorse_healthcheck_durations ', '''
    SELECT date_hour,
        uri,
        count,
        cast(percentiles[offset(75)] as FLOAT64) p75_duration_ms,
        cast(percentiles[offset(95)] as FLOAT64) p95_duration_ms
    FROM (
        SELECT TIMESTAMP_TRUNC(a.timestamp, hour) as date_hour,
            uri,
            count(*) count,
            APPROX_QUANTILES(duration_ms, 100) percentiles
        FROM gcp_perf_analysis.workhorse_thanksgiving a
        WHERE hostname like 'web-%'
        AND uri IN ('/-/health', '/-/liveness', '/-/readiness')
        GROUP BY 1,2
        ORDER BY 1
    )
  ''')

# %%
alt.Chart(workhorse_healthcheck_durations).mark_line().encode(
    y=alt.Y('count'),
    x='date_hour:T',
    color=alt.Color('uri', scale=alt.Scale(scheme='category20c')),
    tooltip='uri:N'
).properties(
    width=1024, height=768
)

# %%
alt.Chart(workhorse_healthcheck_durations).mark_line().encode(
    y=alt.Y('count'),
    x='date_hour:T'
).properties(
    width=1024, height=768
)

# %%
get_ipython().run_cell_magic('bigquery', 'rails_total_time_spent ', '''
    SELECT TIMESTAMP_TRUNC(a.timestamp, day) as date_day,
        count(*) count,
        SUM(duration) total_duration
    FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
    GROUP BY 1
    ORDER BY 1
  ''')
# %%
alt.Chart(rails_total_time_spent).mark_line().encode(
    y=alt.Y('total_duration'),
    x='date_day:T'
).properties(
    width=1024, height=768
)

# %%
get_ipython().run_cell_magic('bigquery', 'rails_max_utilization ', '''
  SELECT TIMESTAMP_TRUNC(date_minute, hour) as date_hour,
         MAX(total_duration) as max_one_minute_total_duration
    FROM (
        SELECT TIMESTAMP_TRUNC(timestamp, minute) as date_minute,
           SUM(duration) total_duration
        FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey
        GROUP BY 1
        ORDER BY 1
    )
    GROUP BY 1
    ORDER BY 1
  ''')

# %%
alt.Chart(rails_max_utilization).mark_line().encode(
    y=alt.Y('max_one_minute_total_duration', scale=alt.Scale(domain=[0, 90000000], clamp=True)),
    x='date_hour:T',
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'controller_total_time_per_week ', 'SELECT TIMESTAMP_TRUNC(a.timestamp, week) as date_week,
        controller,
        SUM(duration) as total_time,
        SUM(gitaly_duration) as total_gitaly_duration,
        SUM(db) as total_db,
        SUM(view) as total_view
FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
WHERE status IS NOT NULL
    AND status != ""
GROUP BY 1,2
ORDER BY 1,3 DESC')


# %%
alt.Chart(controller_total_time_per_week).mark_area().encode(
    x="date_week:T",
    y=alt.Y("total_time:Q", stack="normalize"),
    color=alt.Color('controller:N', scale=alt.Scale(scheme='category20c')),
    tooltip='controller:N'
).properties(
    width=1024, height=768
)


# %%
alt.Chart(controller_total_time_per_week).mark_area().encode(
    x="date_week:T",
    y=alt.Y("total_db:Q", stack="normalize"),
    color=alt.Color('controller:N', scale=alt.Scale(scheme='category20c')),
    tooltip='controller:N'
).properties(
    width=1024, height=768
)


# %%
alt.Chart(controller_total_time_per_week).mark_area().encode(
    x="date_week:T",
    y=alt.Y("total_view:Q", stack="normalize"),
    color=alt.Color('controller:N', scale=alt.Scale(scheme='category20c')),
    tooltip='controller:N'
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'action_db_time ', 'SELECT TIMESTAMP_TRUNC(a.timestamp, week) as date_week,
        action,
        SUM(duration) as total_time,
        SUM(gitaly_duration) as total_gitaly_duration,
        SUM(db) as total_db,
        SUM(view) as total_view
FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
WHERE status IS NOT NULL
    AND status != ""
GROUP BY 1,2
ORDER BY 1,3 DESC')


# %%
get_ipython().run_cell_magic('bigquery', 'db_duration_per_action ', '
SELECT date_day,
       controller,
       action,
       concat(controller, \'#\', action) controller_action,
       count,
       cast(percentiles[offset(50)] as FLOAT64) p50_db,
       cast(percentiles[offset(95)] as FLOAT64) p95_db,
       total_db_time
  FROM (
    SELECT TIMESTAMP_TRUNC(a.timestamp, DAY) as date_day,
          a.controller,
          a.action,
          count(*) count,
          sum(db) as total_db_time,
          APPROX_QUANTILES(db, 100) percentiles
    FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
    INNER JOIN (
          SELECT controller, action
            FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
           GROUP BY 1, 2
           ORDER BY sum(db) DESC
           LIMIT 50
      ) b ON a.controller = b.controller AND a.action = b.action
    WHERE status IS NOT NULL
      AND status != ""
    GROUP BY 1,2, 3
    ORDER BY 1,2, 3
  )')


# %%
alt.Chart(db_duration_per_action).mark_area().encode(
    y=alt.Y('total_db_time'),
    x='date_day:T',
    color=alt.Color('controller_action', scale=alt.Scale(scheme='category20c')),
    tooltip='controller_action:N'
).properties(
    width=1024, height=768
)


# %%
alt.Chart(db_duration_per_action).mark_line().encode(
    y=alt.Y('p50_db'),
    x='date_day:T',
    color=alt.Color('controller_action', scale=alt.Scale(scheme='category20c')),
    tooltip='controller_action:N'
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'db_duration ', '
SELECT date_day,
       count,
       cast(percentiles[offset(50)] as FLOAT64) p50_db,
       cast(percentiles[offset(95)] as FLOAT64) p95_db,
       total_db_time
  FROM (
    SELECT TIMESTAMP_TRUNC(a.timestamp, DAY) as date_day,
          count(*) count,
          sum(db) as total_db_time,
          APPROX_QUANTILES(db, 100) percentiles
    FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
    WHERE status IS NOT NULL
      AND status != ""
    GROUP BY 1
    ORDER BY 1
  )')


# %%
alt.Chart(db_duration).mark_line().encode(
    y=alt.Y('total_db_time'),
    x='date_day:T',
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'web_count ', '
SELECT TIMESTAMP_TRUNC(a.timestamp, DAY) as date_day,
       count(*) as c
    FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
    WHERE status IS NOT NULL
      AND status != ""
    GROUP BY 1
    ORDER BY 1')


# %%
alt.Chart(web_count).mark_line().encode(
    y=alt.Y('c'),
    x='date_day:T',
).properties(
    width=1024, height=768
)


# %%
get_ipython().run_cell_magic('bigquery', 'web_controller_action_count ', '
SELECT TIMESTAMP_TRUNC(a.timestamp, DAY) as date_day,
       concat(a.controller, \'#\', a.action) controller_action,
       count(*) as c
    FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a
    INNER JOIN (
        SELECT controller, action
          FROM gcp_perf_analysis.loving_thanksgiving_like_a_turkey a,

      WHERE status IS NOT NULL
                us != ""


                 GROUP BY 1, 2
        ORDER BY count(*) DESC
        LIMIT 25 )
    b on a.controller = b.controller AND a.action = b.action WHERE stataus IS NOT NULL
      AND status != ""
    GROUP BY 1,2
    ORDER BY 1')


# %%
alt.Chart(web_controller_action_count).mark_line().encode(
    y=alt.Y('c'),
    x='date_day:T',
    color=alt.Color('controller_action', scale=alt.Scale(scheme='category20c')),
    tooltip='controller_action:N'
).properties(
    width=1024, height=768
)


# %%



# %%
alt.Chart(controller_total_time_per_week).mark_area().encode(
    x="date_week:T",
    y=alt.Y("total_gitaly_duration:Q", stack="normalize"),
    color=alt.Color('controller:N', scale=alt.Scale(scheme='category20c')),
    tooltip='controller:N'
).properties(
    width=1024, height=768
)


