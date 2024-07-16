# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.import_dangerfiles(except: %w[changelog commit_messages simple_roulette])
end

diff_stats = git.diff.stats

legacy_metric_changes =
  helper
    .all_changed_files
    .grep(%r{\Alegacy-prometheus-rules/.*\z|^\Alegacy-prometheus-rules-jsonnet/.*\z})
    .select { |file| diff_stats[:files][file][:deletions].positive? if diff_stats[:files][file] }

# Renamed files have a different key than the file name
legacy_metric_changes +=
  helper
    .changes
    .renamed_after
    .files
    .grep(%r{\Alegacy-prometheus-rules/.*\z|^\Alegacy-prometheus-rules-jsonnet/.*\z})

def markdown_list(items)
  items.map { |item| "1. `#{item}`" }.join("\n")
end

if legacy_metric_changes.any?
  warn <<~MESSAGE
    This MR changes some legacy metrics or the files that generate them, please apply these changes to either `mimir-rules/` or `mimir-rules-jsonnet/`:

    #{markdown_list(legacy_metric_changes)}
  MESSAGE
end
