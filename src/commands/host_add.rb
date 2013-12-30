#command 'host install' do |c|
#  c.syntax = "#{PROGRAM} host install <name>"
#  c.description = "Installs the Moai host specified"
#  c.option '--local', 'install under current project folder instead of in the shared location'
#  c.option '--repository URL','git repository to find the host eg git://github.com/halfnelson/moai-host-windows'
#  c.option '--branch','git ref to checkout from repository'
#  c.action do |args,options|
#    name = args.first
#    bail "Name is required" unless name
#    app = MoaiCLI.new
#    puts "hello from host add"
#  end
#end

