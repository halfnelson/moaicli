tmp_root =   File.expand_path( File.join(File.dirname(__FILE__),'..','..'))

if tmp_root.match /^jar:.*/
# are we in the jar?
  require 'java'
  java_import 'org.monkeybars.rawr.Path'

  MOAICLI_ROOT = File.expand_path(File.dirname(Path.new.get_jar_path))
else
  MOAICLI_ROOT = tmp_root
end

require 'lib/app_config'
require 'lib/helper/os_helper'


class Platform
  include OSHelper

  def type
    os
  end


  case os
    when :windows
      require 'lib/helper/windows_helper'
      include WindowsHelper
    when :macosx
      require 'lib/helper/osx_helper'
      include OSXHelper
    when :linux
      require 'lib/helper/linux_helper'
      include LinuxHelper
  end
end

class MoaiCLI
  attr_reader :config,:project_template_path,:sdk_root,:cache_path,:plugin_path,:libmoai_template_path,:deps_root,:hosts_root,:platform

  def initialize
    @project_template_path = File.join(MOAICLI_ROOT,'templates','project')
    @libmoai_template_path = File.join(MOAICLI_ROOT,'templates','libmoai')
    @hosts_root = File.join(MOAICLI_ROOT,'hosts')
    @plugin_path = File.join(MOAICLI_ROOT,"plugins")


    @platform = Platform.new()

    #we should blow away the path on windows since existence of sh.exe breaks cmake
    if platform.type == :windows
      ENV['PATH'] = ""
    end
    @sdk_root = File.join(@platform.support_path,"sdks")
    @cache_path = File.join(@platform.support_path,"cache")
    @deps_root =  File.join(@platform.support_path,'deps')
    install

    @config =  AppConfig.new(@platform.support_path)
  end

   def install
    FileUtils.mkdir_p @sdk_root unless File.exists?(@sdk_root)
    FileUtils.mkdir_p @cache_path unless File.exists?(@cache_path)
    FileUtils.mkdir_p @deps_root unless File.exists?(@deps_root)
  end

end