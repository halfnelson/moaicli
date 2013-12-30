module WindowsHelper


  def add_to_path(path)
    ENV['PATH'] = path + ";" +ENV['PATH'] unless ENV['PATH'].split(/;/).include?(path)
  end

  def support_path
    app_data = ENV['LOCALAPPDATA']
    app_data = ENV['APPDATA'] unless app_data
    File.join(File.expand_path(app_data),'moaicli')
  end


end