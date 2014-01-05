module OSHelper

def os
  require 'rbconfig'
  @os ||= (
  host_os = RbConfig::CONFIG['host_os']
  case host_os
    when /mswin|bccwin|wince|emc/
      :windows
    when /cygwin|msys|mingw/
      raise Error, "MingW/MSYS or Cygwin enviroment not required or supported on windows. Run this from CMD.exe"
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    else
      raise Error, "unknown or unsupported os: #{host_os.inspect}"
  end
  )
end

end
