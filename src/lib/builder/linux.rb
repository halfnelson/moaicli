class LinuxBuilder < BaseBuilder
  def initialize(app,build_config,options)
    super(app,build_config,options)
    bail "Building for Linux requires linux" unless app.platform.type == :linux
  end

  def cmake_platform_define
    'BUILD_LINUX'
  end

  def cmake_makefile_type
    'Unix Makefiles'
  end

  def cmake_platform_params
    "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
  end
end