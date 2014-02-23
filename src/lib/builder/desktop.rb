class DesktopBuilder < BaseBuilder

  def start
    out_dir = config.distribution_root_for_host
    Dir.chdir(out_dir) do
      status "Start", "Launching moai from #{out_dir}"
      if os == :windows
        system("#{cmake_output_bin} main.lua")
      else
        system("./#{cmake_output_bin} main.lua")
      end
    end
  end

  def platform_build
    build_moai(cmake_target, cmake_output, config.host.cmake_params || [])
    distribute
  end

  def distribute
    dest = config.distribution_root_for_host
    #project files
    directory_with_config config.project.src_path, dest
    #executable
    FileUtils.cp cmake_output, dest
  end

end