# frozen_string_literal: true

module RedisTrace
  class KeyPattern
    def self.filter_key(key)
      case ENV['GITLAB_REDIS_CLUSTER']
      when 'persistent'
        # multiline (m) modifier because gitlab-kas:agent_limit can have keynames with binary in them including newlines
        key = key
          .gsub(%r{^(session:lookup:ip:gitlab2:|etag:|action_cable/|sidekiq:cancel:|database-load-balancing/write-location(/main)?/[a-z]+/|runner:build_queue:|gitlab:exclusive_lease:|issues:|gitlab-kas:agent_limit:|gitlab-kas:agent_tracker:conn_by_(project|agent)_id:|gitlab-kas:tunnel_tracker:conn_by_agent_id:|graphql-subscription:|graphql-event::issuableAssigneesUpdated:issuableId:)(.+)}m, '\1$PATTERN')
      when 'cache'
        key = key
          .gsub(%r{^(highlighted-diff-files:merge_request_diffs/)(.+)}, '\1$PATTERN')
          .gsub(%r{^(show_raw_controller:project|ancestor|can_be_resolved_in_ui\?|commit_count_refs/heads/master|commit_count_master|exists\?|last_commit_id_for_path|merge_request_template_names|root_ref|xcode_project\?|issue_template_names|views/shared/projects/_project|application_rate_limiter|branch_names|merged_branch_names|peek:requests|tag_names|branch_count|tag_count|commit_count|size|gitignore|rendered_readme|readme_path|license_key|contribution_guide|gitlab_ci_yml|changelog|license_blob|avatar|metrics_dashboard_paths|has_visible_content\?):(.+)}, '\1:$PATTERN')
          .gsub(%r{^cache:gitlab:(diverging_commit_counts_|github-import/)(.+)}, 'cache:gitlab:\1$PATTERN')
      end

      # Generic replacements
      key
        .gsub(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{8}/, '$UUIDISH')
        .gsub(/([0-9a-f]{64})/, '$LONGHASH')
        .gsub(/([0-9a-f]{40})/, '$LONGHASH')
        .gsub(/([0-9a-f]{32})/, '$HASH')
        .gsub(/([0-9a-f]{30})/, '$HASH')
        .gsub(/([0-9]+)/, '$NUMBER')
    end
  end
end
