# Execute via:
#
# It's recommended to run this in a tmux session (or some other way of surviving
# ssh connection interruption, e.g. nohup)
#
# sudo su -
#
# export GITLAB_STORAGE_MIGRATION_SOURCE_REPO_STORE=nfs-fileXX,nfs-fileYY
# export GITLAB_STORAGE_MIGRATION_TARGET_REPO_STORE=nfs-fileZZ
# (optional) export GITLAB_STORAGE_MIGRATION_BATCH_SIZE=N
# (once sure) export GITLAB_STORAGE_MIGRATION_DRY_RUN=false
#
# gitlab-rails runner move_all_repos_between_nodes.rb 2>&1 | tee -a /tmp/move_all_repos_between_nodes.log
#
# This script traps SIGINT and SIGTERM and waits for its current batch to finish
# before exiting.
# **Be extremely careful** with issuing ^C to send SIGINT if running it in a
# pipeline, as the example above does - the SIGINT will go to the foreground
# process, on the right of the pipeline, and the migration script will get
# SIGPIPE, leading to an unclean shutdown. We could handle SIGPIPE, but we want
# to capture all the logs.


# Monkey patch version of https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/14908
module EE
  module Project
    def change_repository_storage(new_repository_storage_key, sync: false, skip_save: false)
      return if repository_read_only?
      return if repository_storage == new_repository_storage_key

      raise ArgumentError unless ::Gitlab.config.repositories.storages.key?(new_repository_storage_key)

      if sync
        set_repository_read_only!

        begin
          ::Projects::UpdateRepositoryStorageService.new(self).execute(new_repository_storage_key)
        rescue ::Projects::UpdateRepositoryStorageService::RepositoryAlreadyMoved
          Rails.logger.info "#{self.class}: repository already moved: #{full_path}" # rubocop:disable Gitlab/RailsLogger
        end
      else
        run_after_commit { ProjectUpdateRepositoryStorageWorker.perform_async(id, new_repository_storage_key) }
        self.repository_read_only = true

        # In production, this change_repository_storage is only called from
        # ee/app/services/ee/projects/update_service.rb, which will save the
        # project later. We avoid saving the project twice.
        # In rails consoles and admin scripts, by using the default value of
        # skip_save (false), the project doesn't have to be saved after calling
        # this method.
        save! unless skip_save
      end
    end
  end
end

source_repository_store = ENV.fetch('GITLAB_STORAGE_MIGRATION_SOURCE_REPO_STORE')
target_repository_store = ENV.fetch('GITLAB_STORAGE_MIGRATION_TARGET_REPO_STORE')
batch_size = Integer(ENV.fetch('GITLAB_STORAGE_MIGRATION_BATCH_SIZE', '5'))
dry_run = ENV.fetch('GITLAB_STORAGE_MIGRATION_DRY_RUN', 'true')

$stdout.sync = true

def log(msg)
  puts "#{DateTime.now.iso8601} #{msg}"
end


$should_exit = false

def handle_signal(signo)
  log "caught #{Signal.signame(signo)}, exiting after current batch"
  $should_exit = true
end

Signal.trap('INT') { |signo| handle_signal(signo) }
Signal.trap('TERM') { |signo| handle_signal(signo) }

def move_between_shards(source, target, batch_size, dry_run)
  log "will move all projects from #{source} to #{target}"

  exclusions = []
  exclusions_mutex = Mutex.new

  loop do
    exit if $should_exit

    projects_remaining = Integer(Project.where(repository_storage: source).count)
    log "#{projects_remaining} projects remaining in shard #{source}"
    break if projects_remaining.zero?

    projects = Project.where(repository_storage: source).first(batch_size + exclusions.size)

    threads = projects.reject { |p| exclusions.any?("#{p.namespace_id}/#{p.path}") }.map do |project|
      Thread.new do
        move_one_repo(project, target, dry_run)
      rescue ActiveRecord::RecordInvalid => e
        log "caught #{e} from #{project.full_path} - excluding for manual triage"
        exclusions_mutex.synchronize { exclusions << "#{project.namespace_id}/#{project.path}" }
      end
    end

    threads.each(&:join)
  end

  log "finished moving projects from #{source} to #{target}"
end

def move_one_repo(project, target, dry_run)
  # Use namespace_id rather than name to avoid joins.
  desc = "#{project.path} in namespace #{project.namespace_id}"

  was_read_only = project.repository_read_only?
  if was_read_only
    log "#{project.path} was read only, temporarily setting read-write in order to migrate"
    project.update!(repository_read_only: false)
  end

  if dry_run != 'false'
    log "would move #{desc}, but this is a dry run"
  else
    log "moving #{desc}"
    begin
      project.change_repository_storage(target, sync: true)
    rescue Gitlab::Git::CommandError => e
      log "caught exception from project #{project.full_path}: #{e}"
      project.update!(repository_read_only: false) unless was_read_only
    end

    if was_read_only
      log "setting #{project.path} back to readonly"
      project.reload
      project.update!(repository_read_only: true)
    end

    log "finished moving #{desc}"
  end
end

source_repository_store.split(',').each do |source|
  move_between_shards(source, target_repository_store, batch_size, dry_run)
end
