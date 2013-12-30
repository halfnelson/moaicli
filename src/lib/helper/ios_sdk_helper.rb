#complains on windows about lack of tty

module IOSSdkHelper

  def iphone_platform_path
    sdk_platforms_path+'/iPhoneOS.platform/Developer'
  end

  def iphone_simulator_platform_path
    sdk_platforms_path+'/iPhoneSimulator.platform/Developer'
  end

  def iphone_simulator_path
    iphone_simulator_platform_path+"/Applications/iPhone\\ Simulator.app/Contents/MacOS/iPhone\\ Simulator"
  end

  def run_simulator(app_path)
    system("#{iphone_simulator_path} -SimulateApplication #{app_path}" )
  end

  def sdk_platforms_path
    path = %x(xcrun -find make)
    unless path
      bail "Could not find xcode"
    end
    path[/.*?Contents\/Developer/]+"/Platforms"

  end

end