require 'golly-utils/ruby_ext/kernel'
require 'golly-utils/ruby_ext/options'
require 'fileutils'
require 'monitor'
require 'thread'
require 'tmpdir'

module GollyUtils
  module Testing

    # Provides globally-shared, cached, lazily-loaded fixtures that are generated once on-demand, and copied when access
    # is required.
    #
    # @example
    #     describe 'My Git Utility' do
    #       include GollyUtils::Testing::DynamicFixtures
    #
    #       def_fixture :git do                             # Dynamic fixture definition.
    #         system 'git init'                             # Expensive to create.
    #         File.write 'test.txt', 'hello'                # Only runs once.
    #         system 'git add -A && git commit -m x'
    #       end
    #
    #       run_each_in_dynamic_fixture :git                # RSpec helper for fixture usage.
    #
    #       it("detects deleted files") {                   # Runs in a copy of the fixture.
    #         File.delete 'test.txt'                        # Free to modify its fixture copy.
    #         subject.deleted_files.should == %w[test.txt]  # Other tests isolated from these these changes.
    #       }
    #
    #       it("detects new files") {                       # Runs in a clean copy of the fixture.
    #         File.create 'new.txt'                         # Generated quickly by copying cache.
    #         subject.new_files.should == %w[new.txt]       # Unaffected by other tests' fixture modification.
    #       }
    #
    #     end
    module DynamicFixtures

      # @!visibility private
      def self.included(base)
        base.extend ClassMethods
      end
      module ClassMethods

        # Defines a dynamic fixture.
        #
        # @param [Symbol|String] name The dynamic fixture name.
        # @param [Hash] options
        # @option options [nil|String] :cd_into (nil) A fixture subdirectory to change directory into by default when
        #   using the fixture.
        # @option options [nil|String] :dir_name (nil) A specific name to call the temporary directory used when first
        #   creating the fixture. If `nil` then the name will non-deterministic.
        # @param [Proc] block Code that when run in an empty, temporary directory, will create the fixture contents.
        # @yield Yields control in an empty directory at a later point in time.
        # @return [void]
        def def_fixture(name, options={}, &block)
          raise "Block not provided." unless block
          options.validate_option_keys :cd_into, :dir_name

          name= DynamicFixtures.normalise_dynfix_name(name)
          STDERR.warn "Dyanmic fixture being redefined: #{name}." if $gu_dynamic_fixtures[name]
          $gu_dynamic_fixtures[name]= options.merge(block: block)

          nil
        end

        # RSpec helper that directs that each example be run in it's own clean copy of a given dynamic fixture.
        #
        # @param [Symbol|String] name The dynamic fixture name.
        # @param [Hash] options Options to pass to {DynamicFixtures#inside_dynamic_fixture}. See that method for option
        #   details.
        # @return [void]
        # @see DynamicFixtures#inside_dynamic_fixture
        def run_each_in_dynamic_fixture(name, options={})
          raise "Block not supported." if block_given?
          options.validate_option_keys DynamicFixtures::INSIDE_DYNAMIC_FIXTURE_OPTIONS

          class_eval <<-EOB
            around :each do |ex|
              inside_dynamic_fixture(#{name.inspect}, #{options.inspect}){ ex.run }
            end
          EOB

          nil
        end

        # RSpec helper that directs that all examples be run in the same (initially-clean) copy of a given dynamic
        # fixture.
        #
        # @param [Symbol|String] name The dynamic fixture name.
        # @param [Hash] options
        # @option options [nil|String] :dir_name (nil) A specific name to call the empty directory basename.
        # @option options [nil|String] :cd_into (nil) A fixture subdirectory to change directory into when running
        #   examples.
        # @yield Invokes the given block (if one given) once before any examples run, inside the empty dir, to perform
        #   any additional initialisation required.
        # @return [void]
        # @see GollyUtils::Testing::Helpers::ClassMethods#run_all_in_empty_dir
        def run_all_in_dynamic_fixture(name, options={}, &block)
          options.validate_option_keys :cd_into, :dir_name

          require 'golly-utils/testing/rspec/files'
          name= DynamicFixtures.normalise_dynfix_name(name) # actually just wanted dup
          run_all_in_empty_dir(options[:dir_name]) {
            copy_dynamic_fixture name
            instance_eval &block if block
          }

          if cd_into= options[:cd_into]
            class_eval <<-EOB
              around(:each){|ex|
                Dir.chdir(#{cd_into.inspect}){ ex.run }
              }
            EOB
          end
        end

      end

      #------------------------------------------------------------------------------------------------------------------

      # Callback invoked just before creating a dynamic fixture for the first time.
      #
      # Override to customise.
      #
      # @param [Symbol] name The name of the dynamic fixture being created.
      # @return [void]
      def before_dynamic_fixture_creation(name)
      end

      # Callback invoked just after creating a dynamic fixture for the first time.
      #
      # Override to customise.
      #
      # @param [Symbol] name The name of the dynamic fixture being created.
      # @param [Float] creation_time_in_sec The number of seconds taken to create the fixture.
      # @return [void]
      def after_dynamic_fixture_creation(name, creation_time_in_sec)
      end

      # Copies the contents of a dynamic fixture to a given directory.
      #
      # @param [Symbol|String] name The name of the dynamic fixture to copy.
      # @param [String] target_dir The (existing) directory to copy the fixture to.
      # @return [void]
      def copy_dynamic_fixture(name, target_dir = '.')
        FileUtils.cp_r "#{dynamic_fixture_dir name}/.", target_dir
      end

      # Creates a clean copy of a predefined dynamic fixture, changes directory into it and yields. The fixture copy
      # is removed from the file system after the yield block returns.
      #
      # @param [Symbol|String] name The name of the dynamic fixture.
      # @param [Hash] options
      # @option options [nil|String] :cd_into (nil) A fixture subdirectory to change directory into before yielding.
      # @yield Yields control in the directory of a fixture copy.
      # @return The value of the given block.
      def inside_dynamic_fixture(name, options={}, &block)
        options.validate_option_keys INSIDE_DYNAMIC_FIXTURE_OPTIONS

        Dir.mktmpdir {|dir|
          copy_dynamic_fixture name, dir
          df= get_dynamic_fixture_data(name)

          if cd_into= options[:cd_into] || df[:cd_into]
            dir= File.join dir, cd_into
          end

          $gu_dynamic_fixture_chdir_lock.synchronize {
            return Dir.chdir dir, &block
          }
        }
      end

      # @!visibility private
      INSIDE_DYNAMIC_FIXTURE_OPTIONS= [:cd_into].freeze

      private

      def get_dynamic_fixture_data(name)
        name= DynamicFixtures.normalise_dynfix_name(name)
        $gu_dynamic_fixtures[name]
      end

      # Creates and provides the global, temporary directory that will serve as the base directory for generating and
      # storing all dynamic fixtures.
      #
      # Once created it will be automatically removed on process exit.
      #
      # @return [String] A directory.
      def dynamic_fixture_root
        $gu_dynamic_fixture_root || DYNAMIC_FIXTURE_ROOT_LOCK.synchronize {
          $gu_dynamic_fixture_root ||= (
            at_exit_preserving_exit_status {
              FileUtils.remove_entry_secure $gu_dynamic_fixture_root if $gu_dynamic_fixture_root
              $gu_dynamic_fixtures= $gu_dynamic_fixture_root= nil
            }
            Dir.mktmpdir
          )
        }
      end

      DYNAMIC_FIXTURE_ROOT_LOCK= Mutex.new

      # Provides the directory name of a generated dynamic fixture. If the fixture hasn't been generated yet, then this
      # will generate it first.
      #
      # @param [Symbol|String] name The dynamic fixture name.
      # @return [String] A directory.
      def dynamic_fixture_dir(name)
        df= get_dynamic_fixture_data(name)
        raise "Undefined dynamic fixture: #{name}" unless df

        if df[:block]
          $gu_dynamic_fixture_chdir_lock.synchronize {
          # df[:lock].synchronize {
            if df[:block]

              # Start creating dynamic fixture
              before_dynamic_fixture_creation name
              dir= "#{dynamic_fixture_root}/#{name}"
              Dir.mkdir dir

              if subdir= df[:dir_name]
                dir+= "/#{subdir}"
                Dir.mkdir dir
              end

              start_time_stack= (Thread.current[:gu_dynamic_fixture_start_times] ||= [])
              start_time_stack<< Time.now
              begin
                # Create fixture
                Dir.chdir(dir){ instance_eval &df[:block] }
                df.delete :block
                df[:dir]= dir

                dur= Time.now - start_time_stack.last
                start_time_stack.map!{|t| t + dur}
                after_dynamic_fixture_creation name, dur
              ensure
                start_time_stack.pop
              end

            end
          }
        end

        df[:dir].dup
      end

      #-----------------------------------------------------------------------------------------------------------------

      extend ClassMethods

      # @!visibility private
      def self.normalise_dynfix_name(name)
        name.to_sym
      end

      unless $gu_dynamic_fixtures
        $gu_dynamic_fixtures= {}
        $gu_dynamic_fixture_root= nil
        $gu_dynamic_fixture_chdir_lock= Monitor.new
      end

    end
  end
end
