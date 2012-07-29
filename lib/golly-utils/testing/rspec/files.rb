require 'golly-utils/testing/helpers/files'

module GollyUtils
  module TestHelpers
    module ClassMethods

      def run_each_in_empty_dir
        eval <<-EOB
          around :each do |ex|
            inside_empty_dir{ ex.run }
          end
        EOB
      end

      def run_all_in_empty_dir(&block)
        block ||= Proc.new{}
        @@around_all_in_empty_dir_count ||= 0
        @@around_all_in_empty_dir_count += 1
        block_name= :"@@around_all_in_empty_dir_#@@around_all_in_empty_dir_count"
        ::GollyUtils::TestHelpers::ClassMethods.class_variable_set block_name, block
        eval <<-EOB
          before(:all){
            @old_dir,@tmp_dir = inside_empty_dir
            block= ::GollyUtils::TestHelpers::ClassMethods.class_variable_get(:"#{block_name}")
            instance_exec &block
          }
          after(:all){ step_out_of_tmp_dir }
        EOB
      end

    end

    module RSpecMatchers

      #-----------------------------------------------------------------------------------------------------------------

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

      def exist_as_a_file
        ExistAsFile.new
      end
      alias :exist_as_file :exist_as_a_file

      #-----------------------------------------------------------------------------------------------------------------

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

      def exist_as_a_dir
        ExistAsDir.new
      end
      alias :exist_as_dir :exist_as_a_dir

    end
  end
end

RSpec::configure do |config|
  config.include GollyUtils::TestHelpers
  config.include GollyUtils::TestHelpers::RSpecMatchers
end