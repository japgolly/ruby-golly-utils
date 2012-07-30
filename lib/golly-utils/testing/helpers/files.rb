require 'golly-utils/testing/helpers/base'
require 'tmpdir'

module GollyUtils::Testing::Helpers

  # Creates an empty, temporary directory and changes the current directory into it.
  #
  # @example
  #   puts Dir.pwd        # => /home/david/my_project
  #   inside_empty_dir {
  #     puts Dir.pwd      # => /tmp/abcdef123567
  #   }
  #                       # Empty directory now removed
  #   puts Dir.pwd        # => /home/david/my_project
  #
  # @overload inside_empty_dir(&block)
  #   When a block is given, after yielding, the current directory is restored and the temp directory deleted.
  #   @yieldparam [String] dir The newly-created temp dir.
  #   @return The result of yielding.
  # @overload inside_empty_dir
  #   When no block is given the current directory is *not* restored and the temp directory *not* deleted.
  #   @return [String] The newly-created temp dir.
  def inside_empty_dir
    if block_given?
      Dir.mktmpdir {|dir|
        Dir.chdir(dir) {
          (@tmp_dir_stack ||= [])<< :inside_empty_dir
          begin
            return yield dir
          ensure
            @tmp_dir_stack.pop
          end
        }
      }
    else
      x= {}
      x[:old_dir]= Dir.pwd
      x[:tmp_dir]= Dir.mktmpdir
      Dir.chdir x[:tmp_dir]
      (@tmp_dir_stack ||= [])<< x
      x[:tmp_dir]
    end
  end

  # Indicates whether the current directory is one made by {#inside_empty_dir}.
  #
  # @return [Boolean]
  def in_tmp_dir?
    @tmp_dir_stack && !@tmp_dir_stack.empty? or false
  end

  # To be used in conjunction with {#inside_empty_dir}.
  #
  # @example
  #   inside_empty_dir
  #   begin
  #     # Do stuff in empty dir
  #   ensure
  #     step_out_of_tmp_dir
  #   end
  #
  # @return [nil]
  def step_out_of_tmp_dir
    if @tmp_dir_stack
      x= @tmp_dir_stack.pop
      raise "You cannot call step_out_of_tmp_dir() within the yield block of #{x}()" if x.is_a?(Symbol)
      Dir.chdir x[:old_dir]
      FileUtils.rm_rf x[:tmp_dir]
    end
    nil
  end

  # Recursively gets a list of all files.
  #
  # @param [String, nil] dir The directory in which to look for files, or `nil` to indicate the current directory.
  # @return [Array<String>] A sorted array of files. Filenames will be relative to the provided directory.
  def get_files(dir=nil)
    if dir
      Dir.chdir(dir){ get_files }
    else
      Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }.sort
    end
  end

end
