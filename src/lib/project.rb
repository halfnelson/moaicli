
class Project

  attr_reader :root,:config_path,:hosts_root, :config_file,:src_path,:plugin_path,:build_path,:distribution_root
  def initialize


    @root = Dir.pwd
    @config_path = File.join(root,"config")
    @config_file = File.join(config_path,"config.yml")
    @src_path = File.join(root,"src")
    @hosts_root = File.join(root,"hosts")
    @plugin_path = File.join(root,"plugins")
    @build_path = File.join(root,"build")
    @distribution_root = File.join(root,"distribute")

    unless File.exists?(config_file)
      bail("Not in a project directory")
      abort()
    end
  end

  def relative_path(path)
    Pathname.new(path).relative_path_from(Pathname.new(root))
  end


end
