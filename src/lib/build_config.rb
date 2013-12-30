require 'yaml'
require 'config_spartan'
require 'lib/helper/moaisdk_helper'

class BuildConfig

  include MoaiSdkHelper
  attr_accessor :app,:host,:project, :config_file

  def initialize(app,project,host)
    @config = nil
    @sdk = nil
    @app = app
    @host = host
    @project = project
    @config_file = File.join(project.config_path, host.config_file)
    @base_conf = File.join(File.dirname(@config_file),'config.yml')
    ensure_host_config
  end

  def distribution_root_for_host
    File.join(project.distribution_root, host.distribution_path)
  end

  def sdk
    @sdk ||= config_moaisdk(app.sdk_root, sdk_version)
  end

  def sdk_version
    { repository: config.sdk_.repository, ref: config.sdk_.ref }
  end

  def build_dir
    File.join(project.build_path,host.type,host.host_name)
  end

  def digest_file
    File.join(build_dir,'lastbuild.txt')
  end

  def update_digest
    IO.write(digest_file,digest)
  end

  def config_has_changed?
    !(File.exists?(digest_file) && (digest == IO.read(digest_file)))
  end


  def ensure_host_config
    unless host.has_project_config?
      status "Config", "Using project config only"
      return
    end
    unless File.exists?(config_file)
      base_conf = @base_conf
      config = ConfigSpartan.create do
        file base_conf
      end
      template host.config_template_file, config_file, {:config => config }
      status "Config Required", "Configuration for the #{host.type} host #{host.host_name} has been generated at #{config_file}.\n Please edit before running build.", :yellow
      abort
    end
    status "Config", "Using host config from #{project.relative_path(config_file)}", :green
  end

  def save!
    IO.write(config_file,config.to_yaml)
  end

  def digest
    require 'digest'
    @digest ||= Digest::MD5.base64digest(config.to_yaml)
  end

  def config
    base_conf = @base_conf
    config_file = @config_file
    @config ||= ConfigSpartan.create do
      file base_conf
      file config_file if File.exists?(config_file)
    end
  end

  private


  def method_missing(method, *args, &block)
    config.send(method, *args, &block)
  end
end

