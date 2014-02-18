require 'lib/helper/download_helper'


module JdkHelper
class JDK

  include DownloadHelper

  def initialize(deps_root, cache_path)
    @deps_root = deps_root
    @cache_path = cache_path
  end

  def find_jdk_path

  end

  def download_location
  end

  def installed?
    !find_jdk_path.nil?
  end

  def location
    @location ||= find_jdk_path
  end

  def launch_installer
  end

  def download_destination
    File.join(@cache_path, File.basename(download_location))
  end

  def download
    if File.exists?(download_destination)
      status "Download", "Using existing download '#{download_destination}'"
      return
    end
    status "Downloading", "Downloading the JDK"
    download_with_progress download_location, download_destination
  end

  def install!
    return if installed?
    download
    status "Install", "Installing the JDK"
    launch_installer
  end

end

class OSXJDK < JDK
  def find_jdk_path
    %x['/usr/libexec/java_home'].strip
  end
end

class LinuxJDK < JDK
  require 'lib/helper/bzip2_helper'
  include BZip2Helper

  def install_location
    File.join(@deps_root,'jdk')
  end

  def download_location
    "https://s3.amazonaws.com/moaicli.moaiforge.com/jdk-7u25-linux-i586.tar.gz" #TODO: replaceme
  end

  def vendored_jdk
    File.join(install_location,'jdk1.7.0_25')
  end

  def find_jdk_path
    File.exists?(vendored_jdk) ? vendored_jdk : nil
  end

  def launch_installer
    untargzip(download_destination,install_location)
  end
end

class WindowsJDK < JDK


  def download_location
    "https://s3.amazonaws.com/moaicli.moaiforge.com/jdk-7u25-windows-i586.exe" #TODO: replaceme
  end

  def program_files_path
    File.expand_path(ENV['ProgramFiles(x86)'] ||  ENV['ProgramFiles'])
  end



  def find_jdk_path
    fullpath = Dir.glob("#{program_files_path}/java/jdk1.7*").sort.last
    #ant sucks and cant handle spaces in our jdk path on windows
    fullpath = get_short_win32_filename(fullpath) if fullpath
    fullpath
  end

  def launch_installer
    system("#{download_destination} /s ADDLOCAL=\"ToolsFeature,SourceFeature\"")
  end

  private

  def get_short_win32_filename(long_name)
    require 'Win32API'
    win_func = Win32API.new("kernel32","GetShortPathName","PPL","L")
    buf = 0.chr * 256
    buf[0..long_name.length-1] = long_name
    win_func.call(long_name, buf, buf.length)
    return buf.split(0.chr).first
  end

end

def config_jdk
  jdk = nil
  case os
    when :windows
      jdk = WindowsJDK.new(app.deps_root,app.cache_path)
    when :macosx
      jdk = OSXJDK.new(app.deps_root,app.cache_path)
    when :linux
      jdk = LinuxJDK.new(app.deps_root,app.cache_path)
    else
      bail ("No jdk setup for #{os}")
  end

  unless jdk.installed?
    jdk.install! if agree("We couldn't find the JDK on your system, would you like to download and install it automatically?")
    unless jdk.installed? then bail "Please install the JDK before continuing" end
  end

  status "Config", "Using JDK From #{jdk.location}"
  ENV['JAVA_HOME']=jdk.location
  app.platform.add_to_path(File.join(jdk.location,'bin'))
  return jdk
end

end
