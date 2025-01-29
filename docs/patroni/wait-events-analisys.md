# Postgres wait events analisys 

**Table of Contents**

[[_TOC_]]

## Goals and methodologies
This runbook outlines the steps for conducting a drill-down performance analysis, from the node level to individual queries, based on wait events.
A wait events-centric approach is implemented in RDS Performance Insights, and this dashboard offers the same functionality

## Dashboards to be used
1. [https://dashboards.gitlab.net/d/postgres-ai-NEW_postgres_ai_04] Wait events analysis dashboard.

Additionally, for further steps:
1. [Postgres aggregated query performance analysis](https://dashboards.gitlab.net/d/edxi03vbar9q8a/2d8e2a76-e4a8-5343-9709-18eadb0fa1a2?orgId=1) // TODO: update link to a permanent one
1. [Postgres single query performance analysis](https://dashboards.gitlab.net/d/de1633b2zd3wge/4482c6d0-58c5-5473-8cb1-bdf2f09c7757)  // TODO: update link to a permanent one; do not forget to update these links used below in text as well!!

## Analysis steps
### Step 1. Node wait evens (ASH) overview, all wait events are visible and not filtered out

### Step 2. Filter by wait event type. Events of given type are without query ids

### Step 3. Find query ids contributing to given wait type end event    


