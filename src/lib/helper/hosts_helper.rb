module HostsHelper
  def self.list_hosts(host_paths)
    results = []
    results.push("")
    results.push("%-20s | %-40s | %s " % %w(Name Description Version))
    results.push("-" * 75)

    Host.find_all(host_paths).each do
    |host|
      results.push("%-20s | %-40s | %5s" % [host.host_name, host.info.name_, host.info.version_])
    end
    results.join("\n")
  end


  def self.clone(install_path, git_src)
    if File.exists? install_path
      status "Config", "Using moai sdk from #{git_src}"
      return
    end
    status "Cloning", "Moai SDK  from #{git_src}"
    begin
      temp_path = install_path + ".tmp"
      FileUtils.rm_r temp_path if File.exists? temp_path
      git =  GitHelper.clone(git_src,temp_path)
      git.getRepository.close() #if we don't do this, jgit locks the folder and we can't rename
      File.rename temp_path, install_path
    ensure
      FileUtils.rm_r temp_path if File.exists? temp_path #cleanup
    end
  end

  def self.checkout(install_path, git_tag)
    repo = Repo.new(install_path)
    return if repo.branch  =~ /#{git_tag}$/
    status "Checkout", "Switching to ref #{git_tag}"
    begin
      result = repo.smart_checkout git_tag
    rescue Exception => e
      status "Error", "Problem checking out #{git_tag}: #{e.message}", :red
      bail "There was a problem with the configured cloned repository at #{install_path}. Could not checkout tag #{git_tag}:\n #{e.message}"
    end
    unless result[:success]
      bail "We could not checkout the specified host git reference #{git_tag}, there were conflicts with #{result[:result]}"
    end
  end

end
