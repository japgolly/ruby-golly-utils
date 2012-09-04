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
  # @param [nil|String] dir_name If not `nil`, then the empty directory name will be set to the provided value.
  # @overload inside_empty_dir(dir_name = nil, &block)
  #   When a block is given, after yielding, the current directory is restored and the temp directory deleted.
  #   @yieldparam [String] dir The newly-created temp dir.
  #   @return The result of yielding.
  # @overload inside_empty_dir(dir_name = nil)
  #   When no block is given the current directory is *not* restored and the temp directory *not* deleted.
  #   @return [String] The newly-created temp dir.
  def inside_empty_dir(dir_name=nil)
    if block_given?
      Dir.mktmpdir {|dir|
        if dir_name
          dir= File.join dir, dir_name
          Dir.mkdir dir
        end
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
      if dir_name
        x[:tmp_dir]= File.join x[:tmp_dir], dir_name
        Dir.mkdir x[:tmp_dir]
      end
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

  # Returns a list of all files in a directory tree.
  #
  # @param [String, nil] dir The directory to inspect, or `nil` to indicate the current directory.
  # @return [Array<String>] A sorted array of files. Filenames will be relative to the provided directory.
  def get_files(dir=nil)
    get_dir_entries(dir){|f| File.file? f }
  end

  # Returns a list of all subdirectories in a directory.
  #
  # @param [String, nil] dir The directory to inspect, or `nil` to indicate the current directory.
  # @return [Array<String>] A sorted array of dirs. Filenames will be relative to the provided directory. `.` and `..`
  #   will never be returned.
  def get_dirs(dir=nil)
    get_dir_entries(dir){|f| File.directory? f }
  end

  # Returns a list of all files, directories, symlinks, etc in a directory tree.
  #
  # @param [String, nil] dir The directory to inspect, or `nil` to indicate the current directory.
  # @param select_filter An optional filter to be applied to each entry where negative calls result in the entry being
  #   discarded.
  # @return [Array<String>] A sorted array of dir entries. Filenames will be relative to the provided directory. `.` and
  #   `..` will never be returned.
  def get_dir_entries(dir=nil, &select_filter)
    if dir
      Dir.chdir(dir){ get_dir_entries &select_filter }
    else
      Dir.glob('**/*',File::FNM_DOTMATCH)
        .reject{|f| /(?:^|[\\\/]+)\.{1,2}$/ === f } # Ignore:  .  ..  dir/.  dir/..
        .select{|f| select_filter ? select_filter.call(f) : true }
        .sort
    end
  end

end
