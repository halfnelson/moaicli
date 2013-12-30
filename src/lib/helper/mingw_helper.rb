require 'lib/helper/download_helper'
require 'lib/helper/zip_helper'


module MingwHelper
  class Mingw
    attr_reader :download_cache,:install_to

    include DownloadHelper


    def initialize(download_cache, install_to)
      @download_cache = download_cache
      @install_to = install_to
    end

    def download_location
      "https://s3.amazonaws.com/moaicli.moaiforge.com/mingw.exe"
    end

    def launch_installer
      res = system("#{download_destination} x -o\"#{location}\" -y")
      bail "Extraction of mingw failed" if !res
    end

    def installed?
      Dir.exists?(location)
    end

    def bin_path
      File.join(location,"bin")
    end

    def location
      File.join(install_to,'mingw')
    end

    def download_destination
      File.join(download_cache, File.basename(download_location))
    end

    def download
      if File.exists?(download_destination)
        status "Download", "Using existing download '#{download_destination}'"
        return
      end
      status "Downloading", "Downloading MinGW"
      download_with_progress download_location, download_destination
    end

    def install!
      return if installed?
      download
      status "Install", "Installing MinGW"
      launch_installer
    end

  end


  def config_mingw

    download_cache = app.cache_path
    install_to = app.deps_root
    mingw = Mingw.new(download_cache,install_to)


    unless mingw.installed?
      mingw.install! if agree("We need to download and install mingw32 to continue. Do you wish to do this now?")
      unless mingw.installed? then bail "MinGW was required but not installed. Please run again when ready to install" end
    end

    status "Config", "Using MinGW From #{mingw.location}"
    app.platform.add_to_path(File.join(mingw.bin_path))
    mingw
  end

end