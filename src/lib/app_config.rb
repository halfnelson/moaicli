require 'yaml'
require 'config_spartan'

class AppConfig


  def initialize(support_path)
    @config = nil
    @support_path = support_path

  end

  def save!
    IO.write(config_file,@config.to_yaml)
  end

  private


  def config_src
    File.join(MOAICLI_ROOT,'config','app-config.yml')
  end

  def config_root
    File.join(@support_path,'config')
  end

  def config_file
    File.join(config_root,"config.yml")
  end

  def get
    conf = config_file
    unless File.exists? conf
      #copy out of app into appdata
      FileUtils.mkdir_p config_root
      FileUtils.cp config_src, config_file
    end

    @config ||= ConfigSpartan.create do
      file conf
    end
  end

  def method_missing(method, *args, &block)
    get.send(method, *args, &block)
  end
end


