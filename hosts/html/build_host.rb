
module BuildFile

  def start
    require 'webrick'
    root = File.join(out_dir,'www')
    status "Running", "Starting web server hosting your app at http://localhost:8000/moai.html . Ctrl+C to end", :green
    server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => root
    trap 'INT' do server.shutdown end
    server.start
  end

  def build
    #we don't support a bunch of modules, so disable by default
    modules = Hash[ build_config.modules.map {|k, v| [k.downcase, v] } ]

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

    unsupported_modules.each do | mod |
      status 'Warning', "Module [#{mod}] is not supported, trying to compile anyway", :magenta if modules[mod]
    end

    build_moai('host-html-template',build_config.modules,cmake_output,[])
    distribute
  end

  def cmake_output
    File.join(template_dir,'www','moaijs.js')
  end

  def template_dir
    File.join(build_config.build_dir,'bin','libmoai','moai','host-html', 'host-template')
  end

  def out_dir
    File.join(build_config.project.distribution_root,'html')
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
    build_rom
  end

  def build_rom
    require 'lib/helper/emscripten_helper'
    emscripten = EmscriptenHelper.config_emscripten(app)
    rom_dest = File.join(out_dir,'www','moaiapp.rom')
    js_dest = File.join(out_dir,'www','moaiapp.rom.js')
    Dir.chdir(build_config.project.root) do
      cmd = "python #{emscripten.home}/tools/file_packager.py #{rom_dest} --preload src/  --js-output=#{js_dest}"
      unless system(cmd)
        bail "error building rom file"
      end
    end
  end

  def copy_template_files
     copy_directory template_dir, out_dir
  end
end


