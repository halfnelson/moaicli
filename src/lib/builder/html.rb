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
end