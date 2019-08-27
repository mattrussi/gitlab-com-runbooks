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
        self.repository_read_only = true
        save!(validate: false)
        await_git_transfer_completion
        ProjectUpdateRepositoryStorageWorker.new.perform(id, new_repository_storage_key)
      else
        run_after_commit { ProjectUpdateRepositoryStorageWorker.perform_async(id, new_repository_storage_key) }
        self.repository_read_only = true

        # We need to save the record to persist repository_read_only but in some
        # cases, such as `Projects::UpdateService`, the save is performed later.
        save!(validate: false) unless skip_save
      end
    end

    private

    def await_git_transfer_completion
      loop do
        break unless git_transfer_in_progress?

        sleep 10
      end
    end
  end
end

module Projects
  class UpdateRepositoryStorageService
    def execute(new_repository_storage_key)
      # Raising an exception is a little heavy handed but this behavior (doing
      # nothing if the repo is already on the right storage) prevents data
      # loss, so it is valuable for us to be able to observe it via the
      # exception.
      raise RepositoryAlreadyMoved if project.repository_storage == new_repository_storage_key

      result = mirror_repository(new_repository_storage_key)

      if project.wiki.repository_exists?
        result &&= mirror_repository(new_repository_storage_key, type: Gitlab::GlRepository::WIKI)
      end

      if result
        mark_old_paths_for_archive

        project.assign_attributes(repository_storage: new_repository_storage_key, repository_read_only: false)
        project.save(validate: false)
        project.leave_pool_repository
        project.track_project_repository
      else
        project.repository_read_only = false
        project.save(validate: false)
        false
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
    break if projects_remaining <= exclusions.size

    projects = Project.where(repository_storage: source).first(batch_size + exclusions.size)

    threads = projects.reject { |p| exclusions.any?("#{p.namespace_id}/#{p.path}") }.map do |project|
      Thread.new do
        unless move_one_repo(project, target, dry_run)
          log "#{project.full_path} could not be moved - excluding for manual triage"
          exclusions_mutex.synchronize { exclusions << "#{project.namespace_id}/#{project.path}" }
        end
      end
    end

    threads.each(&:join)
  end

  log "finished moving projects from #{source} to #{target}"
end

def move_one_repo(project, target, dry_run)
  # Use namespace_id rather than name to avoid joins.
  desc = "#{project.path} in namespace #{project.namespace_id}"

  # TODO allow_move_read_only param on MR'ed method
  was_read_only = project.repository_read_only?
  if was_read_only
    log "#{project.path} was read only, temporarily setting read-write in order to migrate"
    set_read_only(project, false)
  end

  if dry_run != 'false'
    log "would move #{desc}, but this is a dry run"
  else
    can_be_moved = true

    log "moving #{desc}"
    begin
      can_be_moved = project.change_repository_storage(target, sync: true)
      log "finished moving #{desc}"
    rescue Gitlab::Git::CommandError => e
      log "caught exception from project #{project.full_path}: #{e}"
      set_read_only(project, false) unless was_read_only
    end

    if was_read_only
      log "setting #{project.path} back to readonly"
      project.reload
      set_read_only(project, true)
    end

    can_be_moved
  end
end

def set_read_only(project, read_only)
  project.repository_read_only = read_only
  project.save!(validate: false)
end

source_repository_store.split(',').each do |source|
  move_between_shards(source, target_repository_store, batch_size, dry_run)
end
