require 'lib/helper/android_helper'
require 'lib/helper/moaisdk_helper'

module BuildFile


  include MoaiSdkHelper
  include AndroidHelper
  def start
    sdk = config_android_sdk(10)
    sdk.ensure_device
    #do we have somewhere to run it
    Dir.chdir(File.join(build_dir,'project')) do
      system('ant uninstall')
      system('ant installd')
      system("adb shell am start -a android.intent.action.MAIN -n #{build_config.package}/#{build_config.package}.MoaiActivity")
      system('adb logcat -c')
      system('adb logcat MoaiLog:V AndroidRuntime:E *:S')
    end
  end

  def cmake_output
    File.join(cmake_build_dir,'libs','armeabi-v7a','libmoai.so')
  end

  def disabled_extensions_param
    disabled = []
    (host_config.extensions || {}).each_pair { |k,e|  disabled << k.upcase unless e }
    "-DDISABLED_EXT='#{disabled.join(';')}'"
  end



  def build
    config_ant
    config_jdk
    sdk = config_android_sdk(10)
    config_android_ndk
    build_moai('all',build_config.modules,cmake_output,[disabled_extensions_param])


    build_config[:android_sdk_root] = sdk.sdk_path
    build_config[:android_ndk_root] = sdk.ndk_path


    #create build dir
    if Dir.exists?(build_dir)
      if  build_config.config_has_changed?
        FileUtils.rm_rf(build_dir)
      else
        FileUtils.rm_rf(File.join(assets,'lua'))  #just clear lua if we haven't really poked the host
      end

    end


    FileUtils.mkdir_p(build_dir)



    FileUtils.mkdir_p dest('project','assets')

    FileUtils.mkdir_p dest('project','libs','armeabi-v7a')


    copy_file File.join(cmake_build_dir,'libs','armeabi-v7a','libmoai.so'), File.join(build_dir,'project','libs','armeabi-v7a','libmoai.so')

    copy_directory source_file('project','res'), dest('project','res'), :display_relative=> source_file('project')

    %w( drawable-ldpi drawable-mdpi drawable-hdpi drawable-xhdpi raw).each do |dir|
      FileUtils.mkdir_p dest('project','res', dir)
    end

    %w(ldpi mdpi hdpi xhdpi).each do |type|
      icon = build_config.icon_[type]
      unless icon && File.exists?(icon)
        icon = File.join(host_source,'d.res',"icon-#{type}.png")
      end
      copy_file icon, dest('project','res',"drawable-#{type}",'icon.png')
    end

    #key store
    copy_file build_config.key_store, File.join(build_dir,'project',File.basename(build_config.key_store)) if build_config.key_store

    copy_file source_file('project','.classpath'), dest('project','.classpath')
    copy_file source_file('project','proguard.cfg'), dest('project','proguard.cfg')

    FileUtils.mkdir_p dest('project',package_path)

    simple_template source_file('project','res','values','strings.xml'), dest('project','res','values','strings.xml'), '@NAME@'=>build_config.name

    simple_template source_file('project','.project'), dest('project','.project'), '@NAME@'=>build_config.project_name
    simple_template source_file('project','build.xml'), dest('project','build.xml'), '@NAME@'=>build_config.project_name


    simple_template source_file('project','AndroidManifest.xml'), dest('project','AndroidManifest.xml'),
                    '@DEBUGGABLE@'=>build_config.debug ? "true":"false",
                    '@VERSION_CODE@' => build_config.version_code.to_s,
                    '@VERSION_NAME' => build_config.version_name.to_s


    simple_template source_file('project','ant.properties'), dest('project','ant.properties'),
                    '@KEY_STORE@' => build_config.key_store.to_s,
                    '@KEY_ALIAS@' => build_config.key_alias.to_s,
                    '@KEY_STORE_PASSWORD@' => build_config.key_store_password.to_s,
                    '@KEY_ALIAS_PASSWORD@' => build_config.key_alias_password.to_s

    copy_file  source_file('project','project.properties'), dest('project','project.properties')

    #install all libs
    @dep_index = 1
    configure_extensions(host_config.extensions || {})

    #after libs do some more patching
    simple_template dest('project','AndroidManifest.xml'), dest('project','AndroidManifest.xml'),
                  '@PACKAGE@' => build_config.package,
                  '@SCREEN_ORIENTATION@' => build_config.screen_orientation

    copy_file  source_file('project','local.properties'), dest('project','local.properties')
    Dir.glob(dest('**','local.properties')).each do |file|
      simple_template file, file, '@SDK_ROOT@'=> build_config[:android_sdk_root]
    end


    Dir.glob(dest('**','project.properties')).each do |file|
      simple_template file, file,
                      '@APP_PLATFORM@'=>'android-10'
    end


    #src
    copy_directory source_file('project','src'), dest('project','src'),
                   :exclude_dir => %w(/project/src/app$ project/src/moai$),
                   :display_relative=> source_file('project')

    copy_directory source_file('project','src','app'), dest('project',package_path)
    FileUtils.mkdir_p dest('project','src','com','ziplinegames','moai')
    Dir.glob(File.join(source_file('project','src','moai'),'*')).select {|f| !File.directory? f }.each  do |f|
      copy_file f, dest('project','src','com','ziplinegames','moai', File.basename(f))
    end

    simple_template dest('project',package_path,'MoaiActivity.java'), dest('project',package_path,'MoaiActivity.java'),
                    '@WORKING_DIR@' => build_config.working_dir

    Dir.glob(dest('project',package_path,'*.java')).each do |f|
      simple_template f, f, '@PACKAGE@' => build_config.package
    end

    simple_template dest('project',package_path,'MoaiView.java'), dest('project',package_path,'MoaiView.java'),
                    '@RUN_COMMAND@'=>run_command


    #assets
    copy_file source_file('init.lua'), File.join(assets,'init.lua')

    copy_directory File.join(project.src_path,build_config.src_dir)  , File.join(assets, build_config.working_dir),
                   exclude_dir: %w(\..*), exclude: %w('.*\.sh','.*\.bat'),display_relative: project.src_path


    build_config.asset_dirs.each do |asset_dir|
      copy_directory File.join(project.src_path,asset_dir), File.join(assets,asset_dir)
    end

    release_type = options.release ? 'release':'debug'

    Dir.chdir(File.join(build_dir,'project')) do
      status 'Compiling',"ant #{release_type}"
      res = system "ant #{release_type}"
      bail "Compile failed" unless res
    end

    distribute
    status 'Complete', "Build operation complete", :green

  end

  def distribute
    FileUtils.mkdir_p(out_dir)
    FileUtils.cp apk_out, out_dir
  end



  def run_command
    full_working_dir = File.expand_path(File.join(assets,build_config.working_dir))
    init_file = File.join(assets,'init.lua')
    init_script =  Pathname.new(init_file).relative_path_from(Pathname.new(full_working_dir)).to_path
    scripts = build_config.run.unshift(init_script).map { |file| '"'+file+'"' }.join(',')
    'runScripts ( new String [] { '+scripts+' } );'
  end


  def assets
    File.join(build_dir,'project','assets')
  end

  def manifest
    File.join(build_dir,'project','AndroidManifest.xml')
  end

  def moai_java
    File.join(build_dir,'project','src','com','ziplinegames','moai')
  end

  def classpath
    File.join(build_dir,'project','.classpath')
  end

  def template_package_path
    File.join(build_dir,'project','src','com','getmoai','samples')
  end

  def package_path
    package = host_config.package
    parts = package.split(/\./).unshift('src')
    File.join(*parts)
  end

  def host_config
    build_config
  end

  def host_source
    File.join(build_config.sdk.sdk_path,'ant', 'host-source')
  end

  def source_file(*sub_paths)
    File.join(host_source,'source',*sub_paths)
  end

  def dest(*sub_paths)
    File.join(build_dir,*sub_paths)
  end

  def cmake_build_dir
    File.join(build_config.build_dir,'bin')
  end

  def build_dir
    File.join(build_config.build_dir,'src')
  end

  def out_dir
    build_config.distribution_root_for_host
  end

  def apk_out
    File.join(build_dir,'project','bin',build_config.project_name + (options.release ? '-release':'-debug')+'.apk' )
  end

  def template_exists?(src)
    File.exists?(src) || File.exists?(src+'.tt')
  end




  def configure_extensions(extensions)
    (host_config.extensions || []).each_pair do |lib,enabled|
      if enabled
        #library name is different from option in the case of billing and push
        lib = 'google-billing' if lib.downcase == 'billing'
        lib = 'google-push' if lib.downcase == 'push'
        install_library(lib)
      end
    end
  end


  def install_library(library)
    lib = Lib.new(library,File.join(host_source,'source'))

    insert_into_file manifest, file_content(lib.declarations), :after => /EXTERNAL DECLARATIONS.*?\n/ if template_exists? lib.declarations
    insert_into_file manifest, file_content(lib.permissions), :after => /EXTERNAL PERMISSIONS.*?\n/ if template_exists? lib.permissions

    insert_into_file classpath, file_content(lib.classpath), :after => /EXTERNAL ENTRIES.*?\n/ if template_exists? lib.classpath

    copy_directory lib.moai_path, moai_java if Dir.exists? lib.moai_path
    copy_directory lib.lib_folder, dest('project','libs') if Dir.exists? lib.lib_folder
    copy_directory lib.src, dest('project','src') if Dir.exists? lib.src


    #add projects
    if Dir.exists? lib.project
      copy_directory lib.project, dest(library)
      append_to_file dest('project','project.properties') do
        "\nandroid.library.reference.#@dep_index=../#{library}/\n"
      end
      @dep_index = @dep_index + 1
    end
  end

  class Lib
    attr_accessor :lib, :host_source

    def path
      File.join(host_source,'project','external',lib)
    end

    def moai_path
      File.join(host_source,'project','src','moai',lib)
    end

    def declarations
       File.join(path,'manifest_declarations.xml')
    end

    def permissions
       File.join(path,'manifest_permissions.xml')
    end

    def classpath
      File.join(path,'classpath.xml')
    end

    def project
      File.join(path,'project')
    end

    def lib_folder
      File.join(path,'lib')
    end

    def src
      File.join(path,'src')
    end

    def initialize(lib,host_source)
      @lib = lib
      @host_source = host_source
    end
  end




end