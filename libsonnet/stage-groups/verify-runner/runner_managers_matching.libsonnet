local byRunnerManager = 'by-runner';
local byShard = 'by-shard';
local defaultPartition = byRunnerManager;

local formatQuery(query, partition, arguments={}) =
  local matcher =
      if partition == byRunnerManager then 'instance=~"${runner_manager:pipe}"' else 'shard=~"${shard:pipe}"';
  query % (arguments + {
    runnerManagersMatcher: matcher,
  });

{
  formatQuery:: formatQuery,
  byRunnerManager:: byRunnerManager,
  byShard:: byShard,
  defaultPartition:: defaultPartition,
}
