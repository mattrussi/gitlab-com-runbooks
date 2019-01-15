# Execute via:
# `sudo gitlab-rails runner /<path>/<to>/#{$0}`

require 'optparse'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] --current-file-server <servername> --target-file-server <servername>"
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
    if size > 1600
      abort "Size too large"
    end
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
    move_data_amount_gb = 0 if !move_data_amount_gb
    dry_run = true if dry_run == nil
    wait = 10 if !wait

    @current_fs = current_file_server
    @target_fs = target_file_server
    @move_data = move_data_amount_gb * 1024 * 1024 * 1024
    @dry = dry_run
    @wait_time = wait

    puts "We're moving things from #{@current_fs} _TO_ #{@target_fs}"
    puts "We'll wait up to #{@wait_time} seconds to validate between project moves"

  end

  def move_project(input)
    if @dry
      puts "Would move id:#{input.id}"
    else
      actually_move_it(input, @target_fs)
    end
  end

  def move_many_projects(min, list)
    size = 0
    list.each do |project|
      puts "Project id:#{project.id} is ~#{project.statistics.repository_size / 1024 / 1024 / 1024} GB"
      size += project.statistics.repository_size
      move_project(project)
      break if size > min
    end
  end

  def validate(project, new_server)
    i = 0
    while project.repository_storage != new_server
      sleep 1
      print '.'
      project.reload
      i += 1
      if i == @wait_time
        puts
        puts "Gave up waiting for id:#{project.id} to move"
        break
      end
    end
    puts "Done with id:#{project.id}"
  end

  def actually_move_it(project, new_server)
    puts "Scheduling move id:#{project.id} to #{new_server}"
    project.change_repository_storage(new_server)
    validate(project, new_server)
  end

  def go
    # query all projects on the current file server, sort by size descending,
    # then sort by last activity date ascending
    # I want the most idle largest projects
    projects = Project.joins(:statistics).where(repository_storage: @current_fs).order('project_statistics.repository_size DESC').order('last_activity_at ASC')
    pc = projects.count

    puts "Found #{pc} project(s) on #{@current_fs}"

    if @move_data.zero?
      puts "Option --size not specified, will only move 1 project..."
      puts "Will move id:#{projects.first.id}"
      move_project(projects.first)
    else
      puts "Will move at least #{@move_data / 1024 / 1024 / 1024}GB worth of data"
      move_many_projects(@move_data, projects)
    end
  end
end

parser.parse!

abort("Missing options. Use #{$0} --help to see the list of options available") if options.values.empty?

require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'

foo = MoveIt.new(options[:current_file_server], options[:target_file_server], options[:size], options[:dry_run], options[:wait])
foo.go
