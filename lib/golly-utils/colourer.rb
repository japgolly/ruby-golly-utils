module GollyUtils

  # Helps decorate text with ANSI colour codes.
  class Colourer
    attr_reader :output

    # @param output The target IO object that text will be written to.
    def initialize(output)
      @output= output
    end

    def color_enabled?
      @color ||= output_to_tty?
    end

    def color_enabled=(bool)
      # Ungracefully ripped out of RSpec.
      return unless bool
      @color = true
      if bool && ::RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
        unless ENV['ANSICON']
          warn "You must use ANSICON 1.31 or later (http://adoxa.110mb.com/ansicon/) to use colour on Windows"
          @color = false
        end
      end
    end

    # Wraps text in a given colour code (with a colour-clear code on the end) if colours are enabled.
    # @return [String]
    def add_color(text, color_code)
      color_enabled? ? "#{color_code}#{text}\e[0m" : text
    end

    # Calls `puts` on the output stream with optionally coloured text.
    def puts(text, color_code)
      output.puts add_color(text, color_code)
    end

    private

    def output_to_tty?
      begin
        output.tty?
      rescue NoMethodError
        false
      end
    end

  end
end
