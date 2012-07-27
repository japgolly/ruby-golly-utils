require 'tmpdir'

module GollyUtils
  module TestHelpers

    # @example
    #   inside_empty_dir {
    #     puts Dir.pwd
    #   }
    #   # Dir.pwd restored
    #   # Empty directory now removed
    def inside_empty_dir
      if block_given?
        Dir.mktmpdir {|dir|
          Dir.chdir(dir) {
            yield dir
          }
        }
      else
        dir= Dir.mktmpdir
        old_dir= Dir.pwd
        Dir.chdir dir
        [old_dir,dir]
      end
    end

    # To be used in conjunction with [#inside_empty_dir].
    #
    # @example
    #   @old_dir,@tmp_dir = inside_empty_dir
    #   begin
    #     # Do stuff in empty dir
    #   ensure
    #     step_out_of_tmp_dir
    #   end
    def step_out_of_tmp_dir
      Dir.chdir @old_dir if @old_dir
      FileUtils.rm_rf @tmp_dir if @tmp_dir
      @old_dir= @tmp_dir= nil
    end

    def get_files(dir=nil)
      if dir
        Dir.chdir(dir){ get_files }
      else
        Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }.sort
      end
    end

    #-------------------------------------------------------------------------------------------------------------------

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
    end
  end
end
