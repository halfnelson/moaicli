require 'lib/helper/download_helper'
require 'lib/helper/zip_helper'


module CMakeHelper
  class CMake
    attr_reader :download_cache,:install_to

    include DownloadHelper


    def initialize(download_cache, install_to)
      @download_cache = download_cache
      @install_to = install_to
    end

    def download_location
      #per platform
    end

    def launch_installer
      unzip_file(download_destination, location)
    end

    def installed?
      Dir.exists?(location)
    end

    def bin_path
      File.join(location,"bin")
    end

    def location
      File.join(install_to,'cmake')
    end

    def download_destination
      File.join(download_cache, File.basename(download_location))
    end

    def download
      if File.exists?(download_destination)
        status "Download", "Using existing download '#{download_destination}'"
        return
      end
      status "Downloading", "Downloading CMake"
      download_with_progress download_location, download_destination
    end

    def install!
      return if installed?
      download
      status "Install", "Installing CMake"
      launch_installer
    end

  end

  class WindowsCMake < CMake

    def download_location
      "https://s3.amazonaws.com/moaicli.moaiforge.com/cmake-windows.zip"
    end

  end

  class OSXCMake < CMake

    def launch_installer
      super
      FileUtils.chmod_R "a+x", File.join(location,'bin')
    end

    def download_location
      "https://s3.amazonaws.com/moaicli.moaiforge.com/cmake-osx.zip"
    end

  end

  class LinuxCMake < CMake

    def launch_installer
      super
      FileUtils.chmod_R "a+x", File.join(location,'bin')
    end

    def download_location
      "https://s3.amazonaws.com/moaicli.moaiforge.com/cmake-linux.zip"
    end

  end



  def config_cmake
    cmake = nil
    download_cache = app.cache_path
    install_to = app.deps_root
    case os
      when :windows
        cmake = WindowsCMake.new(download_cache,install_to)
      when :macosx
        cmake = OSXCMake.new(download_cache,install_to)
      when :linux
        cmake = LinuxCMake.new(download_cache,install_to)
      else
        fail ("Cmake not configured for #{os}")
    end

    unless cmake.installed?
      cmake.install! if agree("We need to download and install cmake to continue. Do you wish to do this now?")
      unless cmake.installed? then bail "Cmake was required but not installed. Please run again when ready to install" end
    end

    status "Config", "Using CMake From #{cmake.location}"
    app.platform.add_to_path(File.join(cmake.bin_path))
    return cmake
  end

end