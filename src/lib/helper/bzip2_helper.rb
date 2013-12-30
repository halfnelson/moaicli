require 'rubygems'
require 'rubygems/package'
require 'fileutils'

module BZip2Helper
    def untargzip(targz,destination)
      FileUtils.mkdir_p destination
      system("tar -C #{destination} -xf #{targz}" )
    end

    def untarbizp2(tarbz2, destination)
      FileUtils.mkdir_p destination
      system("tar -C #{destination} -xf #{tarbz2}" )
    end
end