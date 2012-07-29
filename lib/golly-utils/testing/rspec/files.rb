require 'golly-utils/testing/rspec/base'
require 'golly-utils/testing/helpers/files'

module GollyUtils::Testing::Helpers::ClassMethods

  # Runs each RSpec example in a new, empty directory.
  #
  # Old directories are deleted at the end of each example, and the original current-directory restored.
  def run_each_in_empty_dir
    eval <<-EOB
      around :each do |ex|
        inside_empty_dir{ ex.run }
      end
    EOB
  end

  # Runs all RSpec examples (in the current context) in a new, empty directory.
  #
  # The directory is deleted after all examples have run, and the original current-directory restored.
  def run_all_in_empty_dir(&block)
    block ||= Proc.new{}
    @@around_all_in_empty_dir_count ||= 0
    @@around_all_in_empty_dir_count += 1
    block_name= :"@@around_all_in_empty_dir_#@@around_all_in_empty_dir_count"
    SELF.class_variable_set block_name, block
    eval <<-EOB
      before(:all){
        inside_empty_dir
        block= ::#{SELF}.class_variable_get(:"#{block_name}")
        instance_exec &block
      }
      after(:all){ step_out_of_tmp_dir }
    EOB
  end

end

module GollyUtils::Testing::RSpecMatchers

  #-----------------------------------------------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------------------------------------------

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

end
