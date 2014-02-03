module LinuxHelper


  def add_to_path(path)
    ENV['PATH'] = ENV['PATH'] + ":" + path unless ENV['PATH'].split(/:/).include?(path)
  end

  def support_path
     File.join(Dir.home(),'.moaicli')
  end

end