# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'golly-utils/testing/rspec/files'

TMP_TEST_FILE= '.rubbish.tmp'

describe 'RSpec helpers' do
  describe '#run_each_in_empty_dir' do

    context "with no args" do
      run_each_in_empty_dir
      def test
        get_files.should be_empty
        File.write 'hehe', 'hehe'
        get_files.should_not be_empty
      end
      it("should provide each example with an empty directory (1/2)"){ test }
      it("should provide each example with an empty directory (2/2)"){ test }
    end

    context "with name" do
      run_each_in_empty_dir 'good'
      it("should provide a directory with the specified name"){
        File.basename(Dir.pwd).should == 'good'
      }
    end
  end

  describe '#run_all_in_empty_dir' do
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

    context "with name" do
      run_all_in_empty_dir 'good'
      it("should provide a directory with the specified name"){
        File.basename(Dir.pwd).should == 'good'
      }
    end
  end

  describe '#inside_empty_dir' do
    shared_examples "tmp_dir stack" do
      it("should not affect the tmp_dir stack after leaving block"){
        before= (@tmp_dir_stack || []).dup
        old_pwd= Dir.pwd
        inside_empty_dir {
          Dir.pwd.should_not == old_pwd
          get_files().should be_empty
        }
        @tmp_dir_stack.should == before
      }
    end

    include_examples "tmp_dir stack"
    it("should return the block result"){
      inside_empty_dir{666}.should == 666
    }

    context 'within run_each_in_empty_dir' do
      run_each_in_empty_dir
      include_examples "tmp_dir stack"
    end
    context 'within run_all_in_empty_dir' do
      run_all_in_empty_dir
      include_examples "tmp_dir stack"
    end
  end

  describe '#in_tmp_dir?' do
    it("should be false when not in tmp dir"){ in_tmp_dir?.should == false }
    context 'with run_each_in_empty_dir' do
      run_each_in_empty_dir
      it("should be true"){ in_tmp_dir?.should == true }
    end
    context 'with run_all_in_empty_dir' do
      run_all_in_empty_dir
      it("should be true"){ in_tmp_dir?.should == true }
    end
  end

  describe '#run_each_in_empty_dir_unless_in_one_already' do
    run_each_in_empty_dir_unless_in_one_already

    context 'when not in an empty dir' do
      def test
        get_files.should be_empty
        unless $golly_07301028
          $golly_07301028= Dir.pwd
        else
          Dir.pwd.should_not == $golly_07301028 # Assert we've been given a different dir
        end
      end
      it("should provide and an empty directory for all examples (1/2)"){ test }
      it("should provide and an empty directory for all examples (2/2)"){ test }
    end

    context 'with run_all_in_empty_dir' do
      run_all_in_empty_dir
      def test
        get_files.should be_empty
        unless $golly_07301031
          $golly_07301031= Dir.pwd
        else
          Dir.pwd.should == $golly_07301031 # Assert we're in the same dir
        end
      end
      it("should reuse same directory for all examples (1/2)"){ test }
      it("should reuse same directory for all examples (2/2)"){ test }
    end
  end

  describe '#get_dirs' do
    run_each_in_empty_dir
    it("should return subdirectories without . and ..") {
      get_dirs.should be_empty
      Dir.mkdir 'b'
      Dir.mkdir 'a'
      Dir.mkdir 'a/123'
      get_dirs.should == %w[a a/123 b]
    }
    it("should ignore files") {
      File.write 'asd', 'asd'
      get_dirs.should be_empty
    }
    it("should include directories starting with .") {
      Dir.mkdir '.hehe'
      Dir.mkdir 'm'
      Dir.mkdir 'm/.hi'
      get_dirs.should == %w[.hehe m m/.hi]
    }
    it("should jump into the provided directory") {
      Dir.mkdir 'a'
      Dir.mkdir 'b'
      Dir.mkdir 'a/123'
      get_dirs('a').should == %w[123]
    }
  end

end

describe 'RSpec matchers' do
  describe '#exist_as_file' do
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

  describe '#exist_as_dir' do
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

  describe '#be_file_with_contents' do
    run_all_in_empty_dir {
      File.write 'f1', 'abc123'
    }

    def expect_failure(*args)
      expect{
        TMP_TEST_FILE.should *args
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it("should pass if file contents match string"){
      File.write TMP_TEST_FILE, "hehe\n"
      TMP_TEST_FILE.should be_file_with_contents "hehe\n"
    }
    it("should pass if file contents match regex"){
      File.write TMP_TEST_FILE, "omg man"
      TMP_TEST_FILE.should be_file_with_contents /^omg/
    }
    it("should pass if file contents match all given expections"){
      File.write TMP_TEST_FILE, 'omg man 123'
      TMP_TEST_FILE.should be_file_with_contents(/^omg/).and(/123/)
    }
    it("should fail if file contents dont match regex"){
      File.write TMP_TEST_FILE, 'omg man 123'
      expect_failure be_file_with_contents /mann/
    }
    it("should fail if file contents dont match string"){
      File.write TMP_TEST_FILE, 'omg man 123'
      expect_failure be_file_with_contents 'what'
    }
    it("should fail if file contents fail one of multiple expections"){
      File.write TMP_TEST_FILE, 'omg man 123'
      expect_failure be_file_with_contents(/^omg/).and(/1234/)
      expect_failure be_file_with_contents(/^omgx/).and(/123/)
    }
    it("should fail if file doesn't exist"){
      File.delete TMP_TEST_FILE if File.exists? TMP_TEST_FILE
      expect_failure be_file_with_contents //
    }
    it("should normalise file content"){
      File.write TMP_TEST_FILE, "hehe"
      TMP_TEST_FILE.should be_file_with_contents("HEHE").when_normalised_with(&:upcase)
    }
    it("should normalise expectations"){
      File.write TMP_TEST_FILE, "HEHE"
      TMP_TEST_FILE.should be_file_with_contents("hehe").when_normalised_with(&:upcase)
    }
    it("should not try to normalise regex"){
      File.write TMP_TEST_FILE, "hehe"
      TMP_TEST_FILE.should be_file_with_contents(/EH/).when_normalised_with(&:upcase)
    }
    it("should change the meaning of and() when specifying normalisation"){
      File.write TMP_TEST_FILE, "hehe\n"
      TMP_TEST_FILE.should be_file_with_contents('HEHE').when_normalised_with(&:upcase).and(&:chomp)
    }
    it("should fail if file contents match arg provided by and_not()"){
      File.write TMP_TEST_FILE, "abc123\n"
      TMP_TEST_FILE.should be_file_with_contents(/abc/).and_not /wtf/,/man/
      expect_failure be_file_with_contents(/abc/).and_not /123/
    }
    it("should fail if file contents match anything provided by and_not()"){
      File.write TMP_TEST_FILE, "abc123\n"
      expect_failure be_file_with_contents(/abc/).and_not /123/,/man/
      expect_failure be_file_with_contents(/abc/).and_not /wtf/,/123/
    }

    context "failure message" do
      before(:all){ File.write 'f1', 'abc123' }

      it("failure msg describes what's missing"){
        expect{ 'f1'.should be_file_with_contents /456/ }.to raise_error /would have/
        expect{ 'f1'.should be_file_with_contents /456/ }.to raise_error /Expected:.*456/
      }
      it("failure msg excludes what's matching"){
        expect{ 'f1'.should be_file_with_contents /[a-z]/,/456/ }.to raise_error /\A[^z]+\z/
      }
      it("failure msg describes what wasn't expected to match"){
        expect{ 'f1'.should be_file_with_contents(/abc/).and_not /123/ }.to raise_error /would not have/
        expect{ 'f1'.should be_file_with_contents(/abc/).and_not /123/ }.to raise_error /Unexpected:.*123/
      }
      it("negative failure msg describes what's matching"){
        expect{ 'f1'.should_not be_file_with_contents /123/ }.to raise_error /would not have/
        expect{ 'f1'.should_not be_file_with_contents /123/ }.to raise_error /Unexpected:.*123/
      }
    end

  end
end
