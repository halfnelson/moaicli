module FilesHelper
  class FileRule
    attr_accessor :block

    def initialize( &block)
      @block = block
    end

    def is_match?(path)
      false
    end

    def handle(src,dest)
      return false unless is_match?(src)
      block.call(src,dest)
    end
  end

  class FilePatternRule < FileRule
    attr_accessor :pattern
    def initialize(pattern, &block)
      super &block
      @pattern = pattern
    end

    def is_match?(path)
      !!(path =~ pattern)
    end
  end

  class FileLambdaRule < FileRule
    attr_accessor :match_proc
    def initialize(match_proc, &block)
      super &block
      @match_proc = match_proc
    end

    def is_match?(path)
      match_proc.call(path)
    end
  end




  class DirectoryProcessor
    def initialize
      @file_rules = []
    end

    def file_rules
      @file_rules
    end

    def file_rule(pattern , &block)
      @file_rules << FilePatternRule.new(pattern, &block)
    end

    def file_match_rule(match_proc, &block)
      @file_rules << FileLambdaRule(match_proc,&block)
    end

    def handle_entry(src,dest,options)
      return if excluded?(src,options[:exclude])
      file_rules.each do |rule|
        break if rule.handle(src,dest)
      end
    end

    def excluded?(path,exclude)
        return false if !exclude
        match = exclude.find do |reg_exp|
          if reg_exp.to_s.include?'/'
            !!path.match(reg_exp)
          else
            reg = reg_exp.is_a?(Regexp) ? reg_exp : "^"+reg_exp
            !!File.basename(path).match(reg)
          end
        end
        !!match
    end

    def directory(src,dest,options={})
      return if excluded?(src,options[:exclude_dir])
      handle_entry(src,dest,options)
      Dir.foreach(src) do |entry|
        next if ['.','..'].include? entry
        full_src = File.join(src,entry)
        full_dest = File.join(dest,entry)
        if File.directory?(full_src)
          directory(full_src,full_dest,options)
        else
          handle_entry(full_src,full_dest,options)
        end
      end
    end

  end


  def write_if_changed(output, dest)
    unless File.exists?(dest) && (output == IO.read(dest))
      IO.write(dest,output)
    end
  end

  def simple_template_content(src,context)
    content = IO.read(src)
    context.each_pair do |find,replace|
      content.gsub!(find,replace.to_s)
    end
    content
  end

  def simple_template(src,dest,context)
    output = simple_template_content(src,context)
    write_if_changed(output,dest)
  end

  def template_content(src,context)
    require "erb"
    require 'ostruct'
    ctx = OpenStruct.new(context)
    ERB.new(IO.read(src)).result(ctx.instance_eval{binding})
  end

  def file_content(src,context={})
    if File.exists?(src)
        IO.read(src)
      else
        template_content(src+'.tt',context) if File.exists?(src+'.tt')
    end
  end

  def template(src,dest,context)
    output = template_content(src,context)
    write_if_changed(output,dest)
  end

  def copy_file(src,dest)
    FileUtils.cp(src,dest)
  end

  def copy_directory(src,dest,options={})

    src = File.expand_path(src)
    dest = File.expand_path(dest)
    status "Copy Dir","from #{src} to #{dest}"
    processor = DirectoryProcessor.new()

    base_dir = Pathname.new(options[:display_relative] ||src)

    processor.file_rule(/.*/) do |src,dest|
      status "processing", Pathname.new(src).relative_path_from(base_dir).to_s+".. "
      false
    end

    processor.file_rule(/.*/) do |src,dest|
      if File.directory?(src)
        if File.exists?(dest)
          say "exists"
        else
          FileUtils.mkdir_p(dest)
          say "created"
        end
        true
      end
    end

    processor.file_rule(/.*/) do |src,dest|
      if File.file?(src)
        if File.exists?(dest) && (File.mtime(src) <= File.mtime(dest)) #FileUtils.identical?(src,dest)
          say "unmodified"
        else
          FileUtils.cp(src,dest)
          say "copied"
        end
        true
      end
    end
    processor.directory(src,dest,options)

  end

  def directory(src,dest,context)
    processor = DirectoryProcessor.new()


    processor.file_rule(/.*/) do |src,dest|
      status "processing", src+".. "
      false
    end

    processor.file_rule(/.*/) do |src,dest|
      if File.directory?(src)
        if File.exists?(dest)
          say "exists"
        else
          FileUtils.mkdir_p(dest)
          say "created"
        end
        true
      end
    end

    processor.file_rule(/.*\.tt$/) do |src,dest|
      dest = dest.split(/\./)[0..-2].join(".")
      output = template_content(src,context)
      if File.exists?(dest) && (output == IO.read(dest))
        say "unchanged"
      else
        IO.write(dest,output)
        say "processed"
      end
      true
    end

    processor.file_rule(/.*/) do |src,dest|
      if File.file?(src)
        if File.exists?(dest) && FileUtils.identical?(src,dest)
          say "unchanged"
        else
          FileUtils.cp(src,dest)
          say "copied"
        end
        true
      end
    end

    processor.directory(src,dest)
  end


  def append_to_file(dest, *args, &block)
    content = block.nil? ? args.first(): block.call(nil)
    File.open(dest,"a") { |f| f.write(content)}
  end

  def insert_into_file(dest, insert, config)
    content = IO.read(dest)
    content.gsub!(config[:after],"\\0#{insert}")
    IO.write(dest, content)
  end




end