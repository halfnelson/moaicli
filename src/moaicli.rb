$:.unshift File.expand_path(File.dirname(__FILE__))
require 'bundle/bundler/setup'

require 'lib/helper/os_helper'
include OSHelper

require 'ansicolor' if os == :windows
require 'commander/import'
require 'lib/helper/file_helper'
require 'lib/helper/highline_helper'
require 'lib/moaicli'


#global helpers
include FilesHelper
include HighlineHelper

fix_windows_highline if os == :windows

PROGRAM = 'MoaiCLI'
VERSION = '1.5.0-rc1'

Dir.glob(File.join(File.dirname(__FILE__),'commands','*.rb'))  do |filename|
  require filename
end

program :name, PROGRAM
program :version, VERSION
program :description, 'Moai project builder and runner'





