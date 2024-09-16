# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |gitlab_dangerfiles|
  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.import_dangerfiles(except: %w[changelog commit_messages simple_roulette])
end

diff_stats = git.diff.stats

def markdown_list(items)
  items.map { |item| "1. `#{item}`" }.join("\n")
end
