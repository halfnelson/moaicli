
require 'lib/helper/ios_sdk_helper'

module BuildFile

  include IOSSdkHelper

  def disabled_extensions_param
    disabled = []
    (build_config.extensions || {}).each_pair { |k,e|  disabled << k.upcase unless e }
    "-DDISABLED_EXT='#{disabled.join(';')}'"
  end

  def start
    bail "Start is only valid on the simulator atm" unless simulator?

    #then we run
    app_name = 'moai'
    status "Launching", "#{cmake_output_file}/#{app_name}"
    run_simulator("#{cmake_output_file}/#{app_name}" )
  end

  def code_sign_param
    "-DSIGN_IDENTITY='#{build_config.code_sign_identity}'"
  end

  def arch_param
    if simulator?
      "-DCMAKE_OSX_ARCHITECTURES=i386"
    else
      "-DCMAKE_OSX_ARCHITECTURES=armv7"
    end
  end

  def build_params
    [
      disabled_extensions_param,
      code_sign_param,
      arch_param,
      "-DAPP_NAME='#{build_config.name}'",
      "-DAPP_ID='#{build_config.app_id}'",
      "-DAPP_VERSION='#{build_config.version_name}'"

    ]
  end


  def build
    status "Build","Building for #{(build_config.host.type == 'ios_simulator') ? "Simulator":"Device"}"
    build_moai('moai', cmake_output_file, build_params )
  end

  def simulator?
    build_config.host.type == 'ios_simulator'
  end


  def cmake_output_file
    app_name = 'moai'
    simulator = simulator? ? "simulator" : ""
    build_type = options.release ? "Release" : "Debug"
    File.join(build_config.build_dir,"bin","#{build_type}-iphone#{simulator}","#{app_name}.app")
  end
end