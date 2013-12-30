
module BuildFile

  def start
    Dir.chdir(out_dir) do
      status "Start", "Launching moai.exe from #{out_dir}"
      system("moai.exe main.lua")
    end
  end

  def build
    build_moai('moai',build_config.modules,cmake_output,[])
    copy_project_files(out_dir)
    FileUtils.cp cmake_output, out_dir
  end

  def cmake_output
    File.join(File.join(build_config.build_dir,'bin','moai.exe'))
  end

  def out_dir
    File.join(build_config.build_dir,'app')
  end

  def copy_project_files(destination)
    directory_with_config project.src_path, destination
  end
end


