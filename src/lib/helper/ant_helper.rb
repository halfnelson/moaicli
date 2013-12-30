require 'lib/helper/download_helper'
require 'lib/helper/zip_helper'


module AntHelper
  class Ant
    attr_accessor :cache_path, :install_to
    include DownloadHelper

    def initialize(install_to,download_cache)

      @install_to = install_to
      @cache_path = download_cache

    end

    def download_src
      "http://archive.apache.org/dist/ant/binaries/apache-ant-1.8.4-bin.zip"
    end

    def download_destination
      File.join(@cache_path, File.basename(download_src))
    end

    def install_path
      @install_to
    end

    def local_ant_home
      File.join(install_path,'apache-ant-1.8.4')
    end

    def ant_home
      ENV['ANT_HOME'] || local_ant_home
    end

    def ant_bin
      File.join(ant_home,'bin')
    end

    def installed?
      Dir.exists?(ant_home)
    end

    def download
      return if File.exists? download_destination
      status "Downloading", "Apache Ant from #{download_src}"
      download_with_progress download_src, download_destination
    end

    def unzip
      unzip_file(download_destination,install_path)
    end

    def install!
      return if installed?
      download
      unzip
    end
  end


  def config_ant
    ant = Ant.new(File.join(app.deps_root,'ant'),app.cache_path)
    ant.install! unless ant.installed?
    ENV['ANT_HOME']= ant.ant_home
    app.platform.add_to_path(ant.ant_bin)
    status "Config", "Using Apache ANT From #{ant.ant_home}"
    return ant
  end

end