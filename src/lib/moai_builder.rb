require('lib/builder/base')

module MoaiBuilder
  def self.get_builder(app,build_config,options)
      case build_config.host.type.to_sym
        when :windows
          require('lib/builder/windows')
          WindowsBuilder.new(app,build_config,options)
        when :android
          require('lib/builder/android')
          AndroidBuilder.new(app,build_config,options)
        when :ios
          require('lib/builder/ios')
          IOSBuilder.new(app,build_config,options)
        when :ios_simulator
          require('lib/builder/ios')
          IOSBuilder.new(app,build_config,options)
        when :macosx
          require('lib/builder/osx')
          OSXBuilder.new(app,build_config,options)
        when :linux
          require('lib/builder/linux')
          LinuxBuilder.new(app,build_config,options)
        when :html
          require('lib/builder/html')
          HtmlBuilder.new(app,build_config,options)
        else
           bail "No build rules defined for #{build_config.host.type}"
       end
  end
end
