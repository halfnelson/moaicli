require 'lib/helper/download_helper'
require 'uri'
require 'lib/helper/git_helper'

module MoaiSdkHelper



  class MoaiSdk
    attr_accessor :version
    attr_reader :app
    require "rjgit"
    include RJGit


    def initialize(sdk_root,sdk_config)
      @sdk_root = sdk_root
      @config = sdk_config || {}
      @subst = false
    end

    def git_src
      @config[:repository]
    end

    def git_tag
      @config[:ref]
    end

    def sdk_folder
      @config[:folder]
    end


    def id_from_path
      uri = URI(git_src)
      "#{uri.host}#{uri.path.gsub(/\//,'_')}"
    end

    def install_path
      sdk_folder || File.join(@sdk_root,id_from_path)
    end

    def sdk_path
      if @subst
        "#{@subst}:/"
      else
        File.join(install_path)
      end
    end

    def subst!
      require 'java'
      drives = java.io.File.listRoots()
      used_letters = drives.map { |drive| drive.to_s[0]}
      all_letters = ('K'..'Z').to_a
      available_letters = all_letters - used_letters
      return if available_letters.length < 1
      use_letter = available_letters[0]
      if system("subst #{use_letter}: #{sdk_path}")
        @subst = use_letter
        at_exit { system("subst #{use_letter}: /D ")}
      end

    end


    def installed?
      Dir.exists?(sdk_path)
    end

    def repo
      @repo ||= Repo.new(sdk_path)
    end

    def clone
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

    def checkout
      return if repo.branch  =~ /#{git_tag}$/
      status "Checkout", "Switching from ref #{repo.branch} to ref #{git_tag}"
      begin
        result = repo.smart_checkout git_tag
      rescue Exception => e
        status "Error", "Problem checking out #{git_tag}: #{e.message}", :red
        if agree "Would you like to delete and re-clone the repository and try again? [y/n]"
          @repo = nil #cleanup our old instance
          GC.start #no nice way to clean up Repo instances, they hold onto the repository until finalize
          status "Deleting", "Removing old clone"
          FileUtils.rm_r install_path
          clone
          retry
        end
        bail "There was a problem with the configured cloned repository at #{install_path}. Could not checkout tag #{git_tag}:\n #{e.message}"
      end
      unless result[:success]
        bail "We could not checkout the specified sdk git reference #{git_tag}, there were conflicts with #{result[:result]}"
      end
    end

    def install!
      unless installed?
        unless git_src
          if sdk_folder
            bail "New folder specified ''#{sdk_folder}' but no git repository to clone from. "
          else
            bail "No git repository or folder specified in project config"
          end
        end
        clone
      end
      checkout if git_tag
    end

    def update
      begin
        repo.pull()
      rescue org.eclipse.jgit.api.errors.DetachedHeadException => e
        bail "Nothing to do. Update only works for branches #{git_tag}"
      end
      status "Update", "Update was successful"
    end
  end

  def config_moaisdk(sdk_root,version)
    sdk = MoaiSdk.new(sdk_root,version)
    sdk.install!
    status "Config", "Using MOAI Sdk '#{sdk.git_tag}' from #{sdk.sdk_path}"
    sdk
  end



end