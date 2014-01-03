command :new do |c|
  c.syntax = "#{PROGRAM} new NAME"
  c.description = "Creates a new moai project in the folder named NAME"
  c.action do |args,options|
    name = args.first
    bail "Name is required" unless name
    app = MoaiCLI.new
    puts app
    puts name
    project = File.join(Dir.pwd,name)
    if Dir.exists?(project)
      say_error "Project directory already exists!"
      return
    end
    directory app.project_template_path, project, { config: { app_name: name} }
    Dir.chdir(project)
  end
end

