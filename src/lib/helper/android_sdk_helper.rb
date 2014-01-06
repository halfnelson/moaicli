require 'lib/helper/download_helper'
require 'lib/helper/zip_helper'

module AndroidSdkHelper
  class AndroidSdk


    include DownloadHelper

    def initialize(sdk_path, ndk_path, install_to, download_to )
      @sdk_path = sdk_path
      @ndk_path = ndk_path
      @install_to = install_to
      @download_to = download_to
    end

    def download_src
      #platform specific
    end

    def ndk_download_src
      #platform specific
    end

    def sdk_manager
      #platform specific
    end

    def installed?
      Dir.exists?(sdk_path)
    end

    def default_sdk_path
      File.join(@install_to, "android-sdk")
    end

    def default_ndk_path
      File.join(@install_to, "android-ndk")
    end

    def tools_path
      File.join(location,'tools')
    end

    def sdk_path
      @sdk_path || default_sdk_path
    end

    def ndk_path
      @ndk_path || default_ndk_path
    end

    def ndk_location
      @ndk_location ||= ndk_path
    end

    def location
      @location ||= sdk_path
    end

    def platform_tools
      File.join(location, 'platform-tools')
    end

    def launch_installer
      unzip_file(download_destination, File.join(@install_to, "android-sdk"))

      @location = default_sdk_path
    end

    def download_destination
      File.join(@download_to, File.basename(download_src))
    end

    def ndk_download_destination
      File.join(@download_to, File.basename(ndk_download_src))
    end

    def download_ndk
      if File.exists?(ndk_download_destination)
        status "Config", "Using existing download '#{ndk_download_destination}'"
        return
      end
      status "Downloading", "Downloading the Android NDK"
      download_with_progress ndk_download_src, ndk_download_destination
    end

    def download
      if File.exists?(download_destination)
        status "Config", "Using existing download '#{download_destination}'"
        return
      end
      status "Downloading", "Downloading the Android SDK"
      download_with_progress download_src, download_destination
    end

    def install!
      return if installed?
      download
      status "Install", "Installing the Android SDK"
      launch_installer
    end

    def platform_tools_installed?
      Dir.exists? platform_tools
    end

    def install_platform_tools!
      status "Install", "Installing the Android SDK Platform tools"
      Dir.chdir(tools_path) do
        system("#{sdk_manager} update sdk -t platform-tools --no-ui")
        #system("#{sdk_manager} list sdk --no-ui")
        status "Complete", "Android SDK Platform tools installed"
      end

      #todo setup udev rules for linux
      #todo setup usb driver for windows
    end


    def platform_installed?(version)
      Dir.chdir(tools_path) do
        return %x[#{sdk_manager} list target -c].split('\n').any? { |x| x =~ /android-#{version}/ }
      end
    end

    def install_platform(version)
      return if platform_installed?(version)
      status "Install", "Installing SDK Platform #{version}"
      Dir.chdir(tools_path) do
        #get list
        list = %x[#{sdk_manager} list sdk --no-ui].split(/\n/)
                .select {|x| x =~ /(SDK Platform|Google APIs).*?API #{version}/ || x =~ /Build-tools/}
                .collect {|x| /.*?(\d+)\-.*?/.match(x)[1]}.join(',')

        status "Downloading", "API Items (#{list})"
        system("#{sdk_manager} update sdk -t #{list} --no-ui")
      end
    end

    def adb
      "adb"
    end

    def ensure_device
        device_list = %x[#{adb} devices]
        puts "found devices #{device_list}"
        found = device_list.split('\n').any? {|x| x.chomp() =~ /device$/}
        bail ("Device not found or ready for install. Please plug in a device or start an emulator before running start for android") unless found
    end

    def ndk_installed?
      Dir.exists?(ndk_path)
    end

    def extract_ndk(downloaded_file,destination)
      unzip_file(downloaded_file, destination)
    end

    def install_ndk!
      return if ndk_installed?
      download_ndk
      status "Install", "Installing the Android NDK"
      extract_ndk(ndk_download_destination, File.join(@install_to, "android-ndk"))
      @ndk_location = default_ndk_path
    end
  end


  class WindowsAndroidSdk < AndroidSdk

    def default_sdk_path
       File.join(super,"android-sdk-windows")
    end

    def default_ndk_path
      File.join(super,"android-ndk-r8e")
    end

    def download_src
      "http://dl.google.com/android/android-sdk_r22.0.1-windows.zip"
    end

    def ndk_download_src
      "http://dl.google.com/android/ndk/android-ndk-r8e-windows-x86.zip"
    end

    def program_files_path
      File.expand_path(ENV['ProgramFiles(x86)'] ||  ENV['ProgramFiles'])
    end

    def sdk_manager
      "android.bat"
    end

    def ndk_prebuilt_bin
      File.join(ndk_location,'prebuilt','windows','bin')
    end

    def adb
      "adb.exe"
    end
  end

  class OSXAndroidSdk < AndroidSdk

    require "lib/helper/bzip2_helper"
    include BZip2Helper

    def extract_ndk(downloaded_file,destination)
      untarbizp2(downloaded_file,destination)
    end

    def default_sdk_path
      File.join(super,"android-sdk-macosx")
    end

    def default_ndk_path
      File.join(super,"android-ndk-r8e")
    end

    def download_src
      "http://dl.google.com/android/android-sdk_r22.0.5-macosx.zip"
    end

    def ndk_download_src
      "http://dl.google.com/android/ndk/android-ndk-r8e-darwin-x86.tar.bz2"
    end

    def sdk_manager
      "sh android"
    end

    def ndk_prebuilt_bin
      File.join(ndk_location,'prebuilt','macosx','bin')
    end

    def adb
      "adb"
    end
  end

  class LinuxAndroidSdk < AndroidSdk

    require "lib/helper/bzip2_helper"
    include BZip2Helper

    def extract_ndk(downloaded_file,destination)
      untarbizp2(downloaded_file,destination)
    end

    def launch_installer
      untargzip(download_destination, File.join(@install_to, "android-sdk"))
      @location = default_sdk_path
    end

    def default_sdk_path
      File.join(super,"android-sdk-linux")
    end

    def default_ndk_path
      File.join(super,"android-ndk-r8e")
    end

    def download_src
      "http://dl.google.com/android/android-sdk_r22.0.5-linux.tgz"
    end

    def ndk_download_src
      "http://dl.google.com/android/ndk/android-ndk-r8e-linux-x86.tar.bz2"
    end

    def sdk_manager
      "sh android"
    end

    def ndk_prebuilt_bin
      File.join(ndk_location,'prebuilt','linux','bin')
    end

    def adb
      "adb"
    end
  end


  def config_android_ndk
    sdk = nil
    case os
      when :windows
        sdk = WindowsAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      when :macosx
        sdk = OSXAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      when :linux
        sdk = LinuxAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      else
        bail "No android sdk helper defined for #{os}"
    end
    unless sdk.ndk_installed?
      answer = agree("We couldn't find the Android NDK on your system, would you like to download and install it automatically?\n ")
      sdk.install_ndk! if answer
      unless sdk.ndk_installed? then bail "Please install the Android NDK before continuing" end
      app.config.android!.ndk_path = sdk.default_ndk_path
      app.config.save!
    end
    status "Config", "Using NDK From #{sdk.location}"
    ENV['ANDROID_NDK']=sdk.ndk_location
    app.platform.add_to_path(sdk.ndk_location)
    sdk
  end


  def config_android_sdk(version)
    sdk = nil
    case os
      when :windows
        sdk = WindowsAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      when :macosx
        sdk = OSXAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      when :linux
        sdk = LinuxAndroidSdk.new(app.config.android_.sdk_path,app.config.android_.ndk_path,app.deps_root,app.cache_path)
      else
        bail "No android sdk helper defined for #{os}"
    end

    unless sdk.installed?
      answer = agree("We couldn't find the Android SDK on your system, would you like to download and install it automatically?\n ")
      sdk.install! if answer
      unless sdk.installed? then bail "Please install the Android SDK before continuing" end
      app.config.android!.sdk_path = sdk.default_sdk_path
      app.config.save!
    end

    unless sdk.platform_tools_installed?
      answer = agree("We couldn't find the Android SDK platform-tools on your system. Would you like to download and install automatically?\n ")
      sdk.install_platform_tools! if answer
      bail "Please install the platform tools using the Android SDK Manager or this script before continuing"  unless sdk.platform_tools_installed?
    end

    unless sdk.platform_installed?(version)
      answer = agree("We couldn't find the 'android-#{version}' target on your system. Would you like to download and install automatically?\n ")
      sdk.install_platform(version) if answer
      bail "Please install the 'android-#{version}' target using the Android SDK Manager or this script before continuing"  unless sdk.platform_installed?(version)
    end

    status "Config", "Using SDK From #{sdk.location}"
    ENV['ANDROID_SDK_HOME']=sdk.location
    app.platform.add_to_path(sdk.platform_tools)
    return sdk
  end






end
