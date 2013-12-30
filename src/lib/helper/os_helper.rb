module OSHelper

def os
  require 'rbconfig'
  @os ||= (
  host_os = RbConfig::CONFIG['host_os']
  case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    else
      raise Error, "unknown os: #{host_os.inspect}"
  end
  )
end

end
