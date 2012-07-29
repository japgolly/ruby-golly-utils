# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'golly-utils/testing/rspec/files'

TMP_TEST_FILE= '.rubbish.tmp'

describe 'RSpec helpers' do
  context 'run_each_in_empty_dir' do
    run_each_in_empty_dir
    def test
      get_files.should be_empty
      File.write 'hehe', 'hehe'
      get_files.should_not be_empty
    end
    it("should provide each example with an empty directory (1/2)"){ test }
    it("should provide each example with an empty directory (2/2)"){ test }
  end

  context 'run_all_in_empty_dir' do
    context 'without block' do
      run_all_in_empty_dir
      def test
        if $run_all_in_empty_dir__no_block.nil?
          File.write 'hehe1', 'hehe'
          $run_all_in_empty_dir__no_block= true
        end
        get_files.should == %w[hehe1]
      end
      it("should provide and reuse an empty directory for all examples (1/2)"){ test }
      it("should provide and reuse an empty directory for all examples (2/2)"){ test }
    end

    context 'with block' do
      run_all_in_empty_dir do
        File.write 'hehe1', 'hehe'
      end
      def test
        if $run_all_in_empty_dir__block.nil?
          File.write 'hehe2', 'hehe'
          $run_all_in_empty_dir__block= true
        end
        get_files.should == %w[hehe1 hehe2]
      end
      it("should provide and reuse an empty directory for all examples (1/2)"){ test }
      it("should provide and reuse an empty directory for all examples (2/2)"){ test }
    end
  end
end

describe 'RSpec matchers' do
  context 'exist_as_file' do
    run_each_in_empty_dir

    it("should pass when a file exists"){
      File.write TMP_TEST_FILE, 'blah'
      TMP_TEST_FILE.should exist_as_file
    }

    it("should fail when a file doesnt exist"){
      expect{
        TMP_TEST_FILE.should exist_as_file
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    }

    it("should fail when a file is a directory"){
      Dir.mkdir TMP_TEST_FILE
      expect{
        TMP_TEST_FILE.should exist_as_file
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    }
  end

  context 'exist_as_dir' do
    run_each_in_empty_dir

    it("should pass when a dir exists"){
      Dir.mkdir TMP_TEST_FILE
      TMP_TEST_FILE.should exist_as_dir
    }

    it("should fail when a dir doesnt exist"){
      expect{
        TMP_TEST_FILE.should exist_as_dir
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    }

    it("should fail when a dir is a file"){
      File.write TMP_TEST_FILE, 'blah'
      expect{
        TMP_TEST_FILE.should exist_as_dir
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    }
  end
end