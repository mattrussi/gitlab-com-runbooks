# Execute via:
# `sudo gitlab-rails runner /<path>/<to>/#{$PROGRAM_NAME}`

require 'optparse'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] --current-file-server <servername> --target-file-server <servername>"
  opts.on('--current-file-server <servername>', String, 'Current file server we want to move stuff off from') do |server|
    options[:current_file_server] = server
  end

  opts.on('--target-file-server <servername>', String, 'Server to move stuff too') do |server|
    options[:target_file_server] = server
  end

  opts.on('-d', '--dry-run true', TrueClass, 'Will show you what we would be doing') do |dry|
    options[:dry_run] = dry
  end

  opts.on('-s', '--size [N]', Integer, 'Size in GB worth of repo data to move. If no size provided, only 1 repo will move') do |size|
    abort 'Size too large' if size > 1600
    options[:size] = size
  end

  opts.on('-w', '--wait 10', Integer, 'Time to wait in seconds while validating the move has been completed.') do |wait|
    options[:wait] = wait
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

class MoveIt
  def initialize(current_file_server, target_file_server, move_data_amount_gb, dry_run, wait)
    move_data_amount_gb ||= 0
    dry_run = true if dry_run == nil
    wait ||= 10

    @current_fs = current_file_server
    @target_fs = target_file_server
    @move_data = move_data_amount_gb * 1024 * 1024 * 1024
    @dry = dry_run
    @wait_time = wait

    puts "We're moving things from #{@current_fs} _TO_ #{@target_fs}"
    puts "We'll wait up to #{@wait_time} seconds to validate between project moves"
  end

  def move_project(project)
    if @dry
      puts "Would move id:#{project.id}"
    else
      actually_move_it(project, @target_fs)
    end
  end

  def move_many_projects(min_size, list)
    size = 0
    list.each do |item|
      project = Project.find(item)
      puts "Project id:#{project.id} is ~#{project.statistics.repository_size / 1024 / 1024 / 1024} GB"
      size += project.statistics.repository_size
      move_project(project)
      break if size > min_size
    end
  end

  def validate(project, new_server)
    i = 0
    while project.repository_read_only?
      sleep 1
      project.reload
      print '.'
      i += 1
      if i == @wait_time
        puts
        puts "Gave up waiting for id:#{project.id} to move"
        break
      end
    end
    puts
    if project.repository_storage != new_server
      puts "Failed moving id:#{project.id}"
    else
      puts "Success moving id:#{project.id}"
    end
  end

  def actually_move_it(project, new_server)
    print "Scheduling move id:#{project.id} to #{new_server}"
    change_result = project.change_repository_storage(new_server)
    project.save
    if change_result == nil
      puts "Failed scheduling id:#{project.id}"
    else
      validate(project, new_server)
    end
  end

  def go
    # query all projects on the current file server, sort by size descending,
    # then sort by last activity date ascending
    # I want the most idle largest projects
    project_ids = Project.joins(:statistics).where(repository_storage: @current_fs).order('project_statistics.repository_size DESC').order('last_activity_at ASC').pluck(:id)

    puts "Found #{project_ids.count} project(s) on #{@current_fs}"

    if @move_data.zero?
      puts 'Option --size not specified, will only move 1 project...'
      puts "Will move id:#{project_ids.first}"
      project = Project.find(project_ids.first)
      move_project(project)
    else
      puts "Will move at least #{@move_data / 1024 / 1024 / 1024}GB worth of data"
      move_many_projects(@move_data, project_ids)
    end
  end
end

parser.parse!

abort("Missing options. Use #{$PROGRAM_NAME} --help to see the list of options available") if options.values.empty?

require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'

foo = MoveIt.new(options[:current_file_server], options[:target_file_server], options[:size], options[:dry_run], options[:wait])
foo.go
