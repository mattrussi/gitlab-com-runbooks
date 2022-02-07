require './scripts/change/libchange'

# https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6287

change 6287 do |c|
  env = 'gstg'
  google_project = 'gitlab-staging-1'
  hosts = %w[01 02 03].map { |i| "redis-ratelimiting-#{i}-db-#{env}.c.#{google_project}.internal" }

  c.in_progress
  # c.merge_mr 'gitlab-com/gl-infra/chef-repo', 1308
  c.merge_mr 'igorwwwwwwwwwwwwwwwwwwww/my-awesome-project', 2

  hosts.each do |fqdn|
    c.cmd 'ssh', fqdn, 'sudo gitlab-redis-cli info | grep ^redis_version'
    c.expect('version check') { c.prev.output.strip == 'redis_version:6.0.14' }
  end

  c.confirm_prompt
  c.cmd "echo", "scripts/redis-reconfigure.sh", env, "redis-ratelimiting"

  hosts.each do |fqdn|
    c.cmd 'ssh', fqdn, 'sudo gitlab-redis-cli info | grep ^redis_version'
    c.expect('version check') { c.prev.output.strip == 'redis_version:6.2.6' }
  end
end
