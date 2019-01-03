def check_version_two(project)
  i = 0
  while project.storage_version != 2
    print '.'
    sleep(0.25)
    project.reload
    i += 1
    break if i == 100
  end
  puts
end

def migrate(project)
  puts "#{project.full_path} #{project.id}"
  storage_migrator = Gitlab::HashedStorage::Migrator.new
  umm = storage_migrator.migrate(project)
  if umm == true
    # We actually failed here, so this is neat
    puts "Failed on #{project.id}"
  elsif umm.is_a? String
    # Otherwise the output is the job id (i think that what that is at least)
    check_version_two(project)
  else
    puts "pfft, i dunno: #{project.id}"
  end
end

def init_migrate(projects)
  projects.each do |p|
    next unless p.storage_upgradable?
    migrate(p)
  end
end

def go
  initial_count = Project.with_unmigrated_storage.count
  while initial_count != 0
    puts initial_count
    projects = Project.with_unmigrated_storage.last(1000)
    puts projects.count
    init_migrate(projects)
    initial_count = Project.with_unmigrated_storage.count
  end
end

go
