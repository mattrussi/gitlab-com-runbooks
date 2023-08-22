local byRunnerManager = 'by-runner';
local byShard = 'by-shard';
local defaultPartition = byRunnerManager;

local formatQuery(query, partition) =
  local matcher =
      if partition == byRunnerManager then 'instance=~"${runner_manager:pipe}"' else 'shard=~"${shard:pipe}"';
  query % {
    runnerManagersMatcher: matcher,
  };

{
  formatQuery:: formatQuery,
  byRunnerManager:: byRunnerManager,
  byShard:: byShard,
  defaultPartition:: defaultPartition,
}
