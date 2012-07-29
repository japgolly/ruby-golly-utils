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
  #   @return [Array<String>] Two strings respectively: the current-directory beforing entering the temp dir, and the
  #     newly-created temp dir.
  def inside_empty_dir
    if block_given?
      Dir.mktmpdir {|dir|
        Dir.chdir(dir) {
          return yield dir
        }
      }
    else
      dir= Dir.mktmpdir
      old_dir= Dir.pwd
      Dir.chdir dir
      [old_dir,dir]
    end
  end

  # To be used in conjunction with {#inside_empty_dir}.
  #
  # @example
  #   @old_dir,@tmp_dir = inside_empty_dir
  #   begin
  #     # Do stuff in empty dir
  #   ensure
  #     step_out_of_tmp_dir
  #   end
  def step_out_of_tmp_dir
    # TODO Dumb - change inside_empty_dir() to store old/tmp smarter
    Dir.chdir @old_dir if @old_dir
    FileUtils.rm_rf @tmp_dir if @tmp_dir
    @old_dir= @tmp_dir= nil
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
