require 'zip/zip'

def unzip_file (file, destination)
  Zip::ZipFile.open(file) { |zip_file|
    zip_file.restore_permissions = true #we want the executable flag to survive
    zip_file.each { |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    }
  }
  end