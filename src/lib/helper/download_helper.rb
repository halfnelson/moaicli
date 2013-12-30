#complains on windows about lack of tty
suppress_all_warnings { require 'ruby-progressbar'}
require 'open-uri'

module DownloadHelper

BUFFER_SIZE = 8 * 1024
def download_with_progress(download_src,download_dest)
  pbar = nil
  open(download_src, 'r',
                  :content_length_proc => lambda {|t|
                    if t && 0 < t
                      pbar = ProgressBar.create(:title => "Get", :starting_at => 0, :total => t,
                        :format => '%t: |%B| %p%% %e ', :throttle_rate => 1, :length => 79)
                    end
                  },
                  :progress_proc => lambda {|s|
                    pbar.progress = s if pbar
                  }) do |input|
    open(download_dest, "wb") do |output|
      IO.copy_stream(input,output)
    end
  end


end

end