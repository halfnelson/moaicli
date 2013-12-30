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
      @config[:repository] || "https://github.com/moai/moai-dev.git"
    end

    def git_tag
      @config[:ref] || 'Version-1.4p0'
    end

    def id_from_path
      uri = URI(git_src)
      "#{uri.host}#{uri.path.gsub(/\//,'_')}"
    end

    def install_path
      File.join(@sdk_root,id_from_path)
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
      GitHelper.clone(git_src,install_path)
      
    end

    def checkout
      return if repo.branch  =~ /#{git_tag}$/
      status "Checkout", "Switching to ref #{git_tag}"
      begin
        result = repo.smart_checkout git_tag
      rescue Exception => e
        bail e.message
      end
      unless result[:success]
        bail "We could not checkout the specified sdk git reference #{git_tag}, there were conflicts with #{result[:result]}"
      end
    end

    def install!
      clone
      checkout
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