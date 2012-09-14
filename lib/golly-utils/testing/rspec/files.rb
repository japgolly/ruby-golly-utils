require 'golly-utils/testing/rspec/base'
require 'golly-utils/testing/file_helpers'

module GollyUtils::Testing::Helpers::ClassMethods

  # Runs each RSpec example in a new, empty directory.
  #
  # Old directories are deleted at the end of each example, and the original current-directory restored.
  #
  # @param [nil|String] dir_name If not `nil`, then the empty directory name will be set to the provided value.
  # @return [void]
  def run_each_in_empty_dir(dir_name=nil)
    eval <<-EOB
      around :each do |ex|
        inside_empty_dir(#{dir_name.inspect}){ ex.run }
      end
    EOB
  end

  # Runs each RSpec example in a new, empty directory unless the context has already put it in one (for example, via
  # {#run_all_in_empty_dir}).
  #
  # @param [nil|String] dir_name If not `nil`, then the empty directory name will be set to the provided value.
  # @return [void]
  # @see #in_tmp_dir?
  def run_each_in_empty_dir_unless_in_one_already(dir_name=nil)
    eval <<-EOB
      around :each do |ex|
        in_tmp_dir? ? ex.run : inside_empty_dir(#{dir_name.inspect}){ ex.run }
      end
    EOB
  end


  # Runs all RSpec examples (in the current context) in a new, empty directory.
  #
  # The directory is deleted after all examples have run, and the original current-directory restored.
  #
  # @param [nil|String] dir_name If not `nil`, then the empty directory name will be set to the provided value.
  # @yield Invokes the given block (if one given) once before any examples run, inside the empty dir, to perform any
  #   additional initialisation required.
  # @return [void]
  def run_all_in_empty_dir(dir_name=nil, &block)
    block ||= Proc.new{}
    @@around_all_in_empty_dir_count ||= 0
    @@around_all_in_empty_dir_count += 1
    block_name= :"@@around_all_in_empty_dir_#@@around_all_in_empty_dir_count"
    SELF.class_variable_set block_name, block
    eval <<-EOB
      before(:all){
        inside_empty_dir(#{dir_name.inspect})
        block= ::#{SELF}.class_variable_get(:"#{block_name}")
        instance_exec &block
      }
      after(:all){ step_out_of_tmp_dir }
    EOB
  end

end

#-----------------------------------------------------------------------------------------------------------------------

module GollyUtils::Testing::RSpecMatchers

  # @!visibility private
  class ExistAsFile
    def matches?(tgt)
      @tgt= tgt
      File.exists? tgt and File.file? tgt
    end

    def failure_message_for_should
      m "expected that '#@tgt' would be an existing file."
    end

    def failure_message_for_should_not
      m "expected that '#@tgt' would not exist."
    end

    private
    def m(msg)
      dir= File.dirname(@tgt)
      if Dir.exists? dir
        Dir.chdir(dir) {
          files= Dir.glob('*',File::FNM_DOTMATCH).select{|f| File.file? f }.sort
          indir= dir == '.' ? '' : " in #{dir}"
          "#{msg}\nFiles found#{indir}: #{files.join '  '}"
        }
      else
        "#{msg}\nDirectory doesn't exist: #{dir}"
      end
    end
  end

  # Passes if a file exists (relative to the current directory) with a name specified by the target string.
  #
  # Note: This only passes if a file is found; a directory with the same name will fail.
  #
  # @example
  #   'Gemfile'.should exist_as_a_file
  #   '/tmp/stuff'.should_not exist_as_a_file
  def exist_as_a_file
    ExistAsFile.new
  end
  alias :exist_as_file :exist_as_a_file

  #---------------------------------------------------------------------------------------------------------------------

  # @!visibility private
  class ExistAsDir
    def matches?(tgt)
      @tgt= tgt
      Dir.exists? tgt
    end

    def failure_message_for_should
      m "expected that '#@tgt' would be an existing directory."
    end

    def failure_message_for_should_not
      m "expected that '#@tgt' would not exist."
    end

    private
    def m(msg)
      dir= File.expand_path('..',@tgt).sub(Dir.pwd+'/','')
      if Dir.exists? dir
        Dir.chdir(dir) {
          dirs= Dir.glob('*',File::FNM_DOTMATCH).select{|f| File.directory? f }.sort - %w[. ..]
          indir= dir == '.' ? '' : " in #{dir}"
          "#{msg}\nDirs found#{indir}: #{dirs.join '  '}"
        }
      else
        "#{msg}\nDirectory doesn't exist: #{dir}"
      end
    end
  end

  # Passes if a directory exists (relative to the current directory) with a name specified by the target string.
  #
  # @example
  #   'lib'.should exist_as_a_dir
  #   'cache/z01'.should_not exist_as_a_dir
  def exist_as_a_dir
    ExistAsDir.new
  end
  alias :exist_as_dir :exist_as_a_dir

  #---------------------------------------------------------------------------------------------------------------------

  # @!visibility private
  class FileWithContents
    def initialize
      @contents= []
      @not_contents= []
      @normalisation_fns= []
    end

    def and(c1,*cn)
      @contents.concat [c1]+cn
      self
    end

    def and_not(c1,*cn)
      @not_contents.concat [c1]+cn
      self
    end

    def _and_normalisation_fn(&fn)
      @normalisation_fns<< fn
      self
    end

    def when_normalised_with(&fn)
      instance_eval <<-EOB
        alias :and :_and_normalisation_fn
        def and_not(*) raise "and_not() cannot be called after when_normalised_with()." end
      EOB
      self.and &fn
    end
    alias :when_normalized_with :when_normalised_with

    def matches?(file)
      @contents= @contents.flatten.compact.uniq
      @not_contents= @not_contents.flatten.compact.uniq
      file.should ExistAsFile.new
      @filename= file
      @file_content= File.read(file)

      @normalisation_fns.each do |fn|
        @file_content= fn.(@file_content)
        @contents.map!     {|c| c.is_a?(String) ? fn.(c) : c}
        @not_contents.map! {|c| c.is_a?(String) ? fn.(c) : c}
      end

      @failures= []
      @not_failures= []
      @contents.each     {|c| @failures<< c unless c === @file_content }
      @not_contents.each {|c| @not_failures<< c if c === @file_content }

      @failures.empty? and @not_failures.empty?
    end

    def failure_message_for_should
      if !@failures.empty?
        expected_msg @failures
      else
        unexpected_msg @not_failures
      end
    end

    def failure_message_for_should_not
      inv= @contents - @failures
      if !inv.empty?
        unexpected_msg inv
      else
        expected_msg @not_contents - @not_failures
      end
    end

    private

    def expected_msg(expected)
      "expected that '#@filename' would have certain content.\n" \
        + expected.map{|f| "      Expected: #{f.inspect}" }.join("\n") \
        + "\nActual Content: #{@file_content.inspect}"
    end

    def unexpected_msg(unexpected)
      "expected that '#@filename' would not have certain content.\n" \
        + unexpected.map{|f| "Unexpected: #{f.inspect}" }.join("\n") \
        + "\nActual Content: #{@file_content.inspect}"
    end
  end

  # Checks that a file exists and has expected content.
  #
  # @example
  #   # Specify a single string to for a straight 1:1 comparison.
  #   'version.txt'.should be_file_with_contents "2\n"
  #
  #   # Use regex and the and() method to add multiple expectations
  #   'Gemfile'.should be_file_with_contents(/['"]rspec['"]/).and(/['"]golly-utils['"]/)
  #
  #   # Negative checks can be added too
  #   'Gemfile'.should be_file_with_contents(/gemspec/).and_not(/rubygems/)
  #
  # @example With normalisation
  #   # You can specify functions to normalise both the file and expectation.
  #   'version.txt'.should be_file_with_contents("2").when_normalised_with(&:chomp)
  #
  #   # You can add multiple normalisation functions by specifying and() after the first
  #   'stuff.txt'.should be_file_with_contents(/ABC/)
  #                      .and(/DEF/)
  #                      .and(/123\n/)
  #                      .when_normalised_with(&:upcase)
  #                      .and(&:chomp)
  def be_file_with_contents(contents, *extra)
    FileWithContents.new.and(contents).and(extra)
  end
  alias :be_file_with_content :be_file_with_contents
end
