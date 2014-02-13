module BuildFile

  def start
  	Dir.chdir(out_dir) do
      status "Start", "Launching moai from #{out_dir}"
      if os == :windows
        system("moai.exe main.lua")
      else
        system("./moai main.lua")
      end
    end
  end

  def build
	  status "Build", "building host to #{project.relative_path(build_config.build_dir)}"
    build_moai('moai',build_config.modules,cmake_output)
    distribute
  end

  def cmake_output
    if build_config.host.type == 'windows'
      File.join(File.join(build_config.build_dir,'bin','host-glut', 'moai.exe'))
    else
      File.join(File.join(build_config.build_dir,'bin','host-glut', 'moai'))
    end
  end

  def distribute
    copy_project_files(out_dir)
    FileUtils.cp cmake_output, out_dir
  end

  def out_dir
    build_config.distribution_root_for_host
  end

  def copy_project_files(destination)
    directory_with_config project.src_path, destination
  end
end
