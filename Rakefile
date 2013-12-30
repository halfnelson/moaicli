require 'rawr'

namespace "moaicli" do
  task :package => ["rawr:jar"] do
    FileUtils.cp_r 'templates', File.join('package','jar')
    FileUtils.cp_r 'plugins', File.join('package','jar')
    FileUtils.cp_r 'hosts', File.join('package','jar')
    FileUtils.cp_r 'config', File.join('package','jar')
  end
end
