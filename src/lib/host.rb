require 'config_spartan'

class Host
  attr_accessor :host_name
  attr_reader :path,:cmake_path,:build_file,:config_template_file,:config_file,:distribution_path,:has_project_config,:type

  def initialize(name,path,platform=nil)
     @host_name= name
     @path = path
     @cmake_path =  File.join(path,'cmake')
     @build_file = File.join(path,'build_host.rb')
     @config_template_file = File.join(path,'config.yml.tt')
     @config_file =   "#{host_name}_config.yml"
     @info_file = File.join(path,'host-info.yml')

     @type = get_platform(platform)
  end

  def distribution_path
    File.join(type,host_name)
  end

  def supported_platforms
    info.platforms_.kind_of?(Array) ? info.platforms_ : []
  end

  def set_platform(platform)
    @type = get_platform(platform)
  end

  def get_platform(platform)
    if platform
      unless supported_platforms.include?(platform)
        bail ("platform #{platform} is not supported for host #{host_name} valid values are #{supported_platforms}")
      end
      status "Platform", "switching to requested platform #{platform}"
      return platform
    end
    if supported_platforms.include?(os.to_s)
      status "Platform", "Selecting current os (#{os.to_s}) as default platform"
      return os.to_s
    end
    status "Platform", "Selecting first available platform as current: #{supported_platforms.first}"
    supported_platforms.first
  end

  def has_project_config?
    File.exists?(config_template_file)
  end

  def cmake_file
    File.join(cmake_path,'CMakeLists.txt')
  end

  def has_cmake_file?
    File.exists? cmake_file
  end

  def has_info?
    File.exists? @info_file
  end

  def output_name
    has_info? and info.output_name
  end

  def output_directory
    has_info? and info.output_directory
  end

  def target
    has_info? and info.target
  end

  def cmake_params
    has_info? and (info.cmake_params.kind_of?(Array) ? info.cmake_params : [ info.cmake_params ])
  end

  def android_source
    has_info? and info.android_source
  end

  def info
    bail "host '#{host_name}' at #{path} does not have a host-info.yml file" unless has_info?
    info_file = @info_file
    @info ||= ConfigSpartan.create do
      file info_file
    end
  end

  def self.find_all(paths)
    hosts = []
    paths.each() do |path|
      next unless Dir.exists? path
      Dir.foreach(path) { |name|
        host_path = File.join(path,name)
        if File.exists?(File.join(host_path,'host-info.yml'))
          hosts.push(Host.new(name,host_path))
        end
      }
    end
    hosts
  end

  def self.find_host(name,paths)
    paths.each() do |path|
      host_path = File.join(path,name)
      if File.exists?(File.join(host_path,'host-info.yml'))
        return Host.new(name,host_path)
      end
    end
    return FALSE
  end
end
