class OSXBuilder < BaseBuilder
  def initialize(app,build_config,options)
    super(app,build_config,options)
    bail "Building for OSX requires MacOSX" unless app.platform.type == :macosx
  end

  def cmake_platform_define
    'BUILD_OSX'
  end

  def cmake_makefile_type
    'Unix Makefiles'
  end

  def cmake_platform_params
    "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
  end
end
