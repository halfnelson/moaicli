require 'lib/helper/download_helper'
require 'lib/helper/zip_helper'


module EmscriptenHelper
  class Emscripten
    attr_reader :download_cache,:install_to

    include DownloadHelper

    def initialize(download_cache, install_to)
      @download_cache = download_cache
      @install_to = install_to
    end

    def download_location

    end

    def launch_installer

    end

    def home
      File.join(root,'emscripten','1.7.1')
    end

    def emcc
      File.join(home,'emcc')
    end

    def empp
      File.join(home,'em++')
    end

    def root
      File.join(location,'emsdk-portable')
    end

    def cmake_toolchain
      File.join(home,'cmake','Platform','Emscripten.cmake')
    end

    def clang_path

    end

    def node_path

    end

    def node_bin

    end

    def python_path

    end

    def temp_path
      '/tmp'
    end

    def installed?
      Dir.exists?(location)
    end

    def location
      File.join(install_to,'emscripten')
    end

    def download_destination
      File.join(download_cache, File.basename(download_location))
    end

    def download
      if File.exists?(download_destination)
        status "Download", "Using existing download '#{download_destination}'"
        return
      end
      status "Downloading", "Downloading EmscriptenSDK"
      download_with_progress download_location, download_destination
    end

    def install!
      return if installed?
      download
      status "Install", "Installing Emscripten SDK"
      launch_installer
      create_config
    end

    def config_file
      File.join(location,'emscripten.conf')
    end

    def create_config
      File.open(config_file,  "w+") do |file|
        file.puts <<CONF
import os
EMSCRIPTEN_ROOT='#{home}'
JAVA = 'java'
NODE_JS = os.path.expanduser('#{node_bin}')
LLVM_ROOT = os.path.expanduser('#{clang_path}')
PYTHON = os.path.expanduser('#{python_bin}')
SPIDERMONKEY_ENGINE = ''
V8_ENGINE = ''
TEMP_DIR = '#{temp_path}'
COMPILER_ENGINE = NODE_JS
JS_ENGINES = [NODE_JS]
CONF
      end
    end

  end

  class WindowsEmscripten < Emscripten
    def download_location
      "https://s3.amazonaws.com/moaicli.moaiforge.com/emsdk_win.exe"
    end

    def launch_installer
      res = system("#{download_destination} x -o\"#{location}\" -y")
      bail "Extraction of emscripten failed" if !res
    end

    def emcc
      File.join(home,'emcc.bat')
    end

    def empp
      File.join(home,'em++.bat')
    end

    def clang_path
      File.join(root,'clang','3.2_32bit')
    end

    def node_path
      File.join(root,'node','0.10.17_32bit')
    end

    def node_bin
      File.join(node_path, "node.exe")
    end

    def python_path
      File.join(root,'python','2.7.5.1_32bit')
    end

    def python_bin
      File.join(python_path,'python.exe')
    end

    def temp_path
      ENV['TEMP']
    end
  end

  @@sdk = nil

  def self.config_emscripten(app)

    return @@sdk if @@sdk


    sdk = nil
    case os
      when :windows
        sdk = WindowsEmscripten.new(app.cache_path, app.deps_root)
      else
        bail "No emscripten sdk helper defined for #{os}"
    end

    unless sdk.installed?
      sdk.install! if agree("We need to download and install the EmscriptenSDK to continue. Do you wish to do this now?")
      unless sdk.installed? then bail "EmscriptenSDK was required but not installed. Please run again when ready to install" end
    end

    status "Config", "Using EmscriptenSDK From #{sdk.location}"
    app.platform.add_to_path(sdk.clang_path)
    app.platform.add_to_path(sdk.node_path)
    app.platform.add_to_path(sdk.python_path)
    app.platform.add_to_path(sdk.home)

    #expose java for closure
    require 'java'
    java_bin =   File.join(java.lang.System.getProperty("java.home"),'bin')
    status "Config", "Closure compiler will use java from #{java_bin}"
    app.platform.add_to_path(java_bin)

    ENV['EM_CONFIG'] = sdk.config_file
    #ENV['EMCC_DEBUG'] = "1"

    @@sdk = sdk
    sdk
  end

end