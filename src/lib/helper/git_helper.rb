  require "rjgit"
  class CloneProgress

    include RJGit
    include org.eclipse.jgit.lib.ProgressMonitor
    suppress_all_warnings { require 'ruby-progressbar'}
    attr_accessor :progress
    def initialize
      @progress = nil
    end

    def is_cancelled
      false
    end

    def begin_task(title,total_work)
      @total = total_work
      @progress =ProgressBar.create(:title => title, :starting_at => 0, :total => total_work,
                                    :format => '%t: |%B| %p%% %e ', :throttle_rate => 1, :length => 79) if total_work > 0
      @progress = nil if total_work == 0
    end

    def end_task()
    end

    def start(total)
      @steps = total
    end

    def update(complete)
      progress.progress += complete if progress
    end
  end

  module RepoExt
    def branch_list
      branch_list = self.git.jgit.branchList().setListMode(org.eclipse.jgit.api.ListBranchCommand::ListMode::ALL).call()
      branches = Array.new
      branch_list.each do |b|
        branches << b.get_name
      end
      branches
    end

    def tag_list
      tag_list = self.git.jgit.tagList().call()
      tags = Array.new
      tag_list.each do |t|
        tags << t.get_name
      end
      tags
    end

    def has_local_branch?(branch_name)
      branch_list.include? "refs/heads/#{branch_name}"
    end

    def has_origin_branch?(branch_name)
      branch_list.include? "refs/remotes/origin/#{branch_name}"
    end

    def has_tag?(branch_name)
      tag_list.include? "refs/tags/#{branch_name}"
    end

    def update_submodules
      self.git.jgit.submoduleInit().call()
      self.git.jgit.submoduleUpdate().call()
    end

    #checks out a branch or finds a remote branch or tag. Updates submodules
    def smart_checkout(branch_name)
      result={}
      begin
        if has_local_branch?(branch_name)
          res = checkout(branch_name)
          update_submodules
          return res
        end

        has_fetched = false
        begin
          start_point = nil
          is_tag = false
          if has_origin_branch?(branch_name)
            start_point = "refs/remotes/origin/" + branch_name
          elsif has_tag?(branch_name)
            is_tag = true
            start_point = "refs/tags/" + branch_name
          else
            raise "No branch/tag #{branch_name} found"
          end
        rescue Exception => e
            if has_fetched then
              raise e
            end
            #try a fetch
            begin
             has_fetched = true
             self.git.jgit.fetch().call()
            rescue Exception => e2
              #raise our original exception if we couldn't fetch
              raise e
            end
            #after a fetch try again.
            retry
        end



        if is_tag
         command = self.git.jgit.checkout().setName(branch_name)
         command.call()
        else
         command = self.git.jgit.branchCreate().setName(branch_name)
                   .setUpstreamMode(org.eclipse.jgit.api.CreateBranchCommand::SetupUpstreamMode::SET_UPSTREAM)
                    .setStartPoint(start_point)
                    .setForce(true)
         command.call()
         
          self.git.jgit.checkout().setName(branch_name).call()
         end
        result[:success] = true
        result[:result] = self.git.jgit.get_repository.get_full_branch
        update_submodules
      rescue Java::OrgEclipseJgitApiErrors::CheckoutConflictException => conflict
        result[:success] = false
        result[:result] = conflict.get_conflicting_paths
      end
      result
    end


    def pull
      self.git.jgit.pull().call()
    end

   
        

  end


  class RJGit::Repo
    include RepoExt
  end


  class GitHelper

    def self.git
      org.eclipse.jgit.api.Git
    end

    def self.clone(git_src,install_path)
      FileUtils::mkdir_p install_path
      self.git.clone_repository
        .setURI(git_src)
        .set_directory(java.io.File.new(install_path))
        .set_clone_all_branches(true)
        .setCloneSubmodules(true)
        .setProgressMonitor(CloneProgress.new())
        .call()
    end

  end




