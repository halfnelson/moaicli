class HtmlBuilder < BaseBuilder
  require 'lib/helper/emscripten_helper'
  require 'lib/helper/mingw_helper'

  attr_accessor :emscripten
  def initialize(app,build_config,options)
    super(app,build_config,options)
    @emscripten = EmscriptenHelper.config_emscripten(app)
    if os == :windows
      @mingw = MingwHelper.config_mingw(app)
    end
  end

  def cmake_platform_define
    'BUILD_HTML'
  end

  def cmake_makefile_type
    case os
      when :windows
        'MinGW Makefiles'
      else
        'Unix Makefiles'
    end
  end

  def cmake_platform_params
    params = []
    params.push "-G \"#{cmake_makefile_type}\""
    params.push "-D#{cmake_platform_define}=true"
    params.push "-DCMAKE_TOOLCHAIN_FILE='#{emscripten.cmake_toolchain}'"
    params.push  "-DEMSCRIPTEN_ROOT_PATH='#{emscripten.home}'"

    params.join(" ")
  end


  def start
    require 'webrick'
    root = File.join(out_dir,'www')
    status "Running", "Starting web server hosting your app at http://localhost:8000/moai.html . Ctrl+C to end", :green
    server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => root
    trap 'INT' do server.shutdown end
    server.start
  end

  def platform_build
    #we don't support a bunch of modules, so disable by default
    modules = Hash[ config.modules.map {|k, v| [k.downcase, v] } ]

    unsupported_modules = %w[
      chipmunk
      curl
      crypto
      expat
      jpg
      mongoose
      ogg
      openssl
      sqlite3
      sfmt
      vorbis
      http_client
      luaext
    ]

    if modules['luajit']
      status 'Warning', "LuaJIT is not supported by emscripten yet. Falling back to normal lua", :magenta
      config.modules.delete_if { |k,v| k.downcase == 'luajit' }
    end

    unsupported_modules.each do | mod |
      status 'Warning', "Module [#{mod}] is not supported, trying to compile anyway", :magenta if modules[mod]
    end

    build_moai(cmake_target,cmake_output,[])
    distribute
  end

  def distribute
    unless File.exists?(out_dir)
      FileUtils.mkdir_p(out_dir)
      #never overwrite, so we only do it here
      copy_template_files
    end
    #copy moaijs.js
    FileUtils.cp cmake_output, File.join(out_dir,'www','moaijs.js')
    #build the rom from the lua files
    status "Distribute", "Building application rom"
    build_rom
  end

  def packager
    File.join(config.sdk.sdk_path,'src','host-html','host-template', 'file_packager.py')
  end

  def build_rom
    require 'lib/helper/emscripten_helper'
    rom_dest = File.join(out_dir,'www','moaiapp.rom')
    js_dest = File.join(out_dir,'www','moaiapp.rom.js')
    Dir.chdir(config.project.root) do
      cmd = "python #{packager} #{rom_dest} --preload src@/  --js-output=#{js_dest} --as-json"
      unless system(cmd)
        bail "error building rom file"
      end
    end
  end

  def copy_template_files
    copy_directory template_dir, out_dir
  end

  def cmake_output_bin
    File.join('www','moaijs.js')
  end

  def cmake_output
    File.join(template_dir,cmake_output_bin)
  end

  def template_dir
    File.join(cmake_output_dir, 'host-template')
  end

  def out_dir
    config.distribution_root_for_host
  end
end