module HighlineHelper
def status(status,message,colour = nil)
  colour = colour || ((status == "error") && :red) || :yellow
  $terminal.indent do
    say HighLine.String(status).color(colour)+"\t"
    $terminal.indent { say message}
  end
end

def bail(message)
  $terminal.indent do
    say HighLine.String("Error: ").red + message
  end
  abort
end

def suppress_all_warnings
  old_verbose = $VERBOSE
  begin
    $VERBOSE = nil
    yield if block_given?
  ensure
    # always re-set to old value, even if block raises an exception
    $VERBOSE = old_verbose
  end
end

def fix_windows_highline
  #patch highline for windows
    #windows puts a 13 after each newline which highline leaves in the buffer (actually jline)
    #which breaks system() calls for some strange reason
    HighLine.class_eval do
      alias_method :original_get_line, :get_line
      def get_line()
        res = original_get_line
        @input.getbyte() #there is always a \x13 after a get_line call in windows
        res
      end
    end
end

end
