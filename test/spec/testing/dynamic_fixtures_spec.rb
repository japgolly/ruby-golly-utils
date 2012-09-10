# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'golly-utils/testing/dynamic_fixtures'
require 'golly-utils/testing/rspec/files'

describe GollyUtils::Testing::DynamicFixtures do
  include described_class

  $gu_dynfix_a_count= 0
  def_fixture :a do
    $gu_dynfix_a_count += 1
    Dir.mkdir 'aa'
    File.write 'aa/abc', '123'
    File.write 'a_parent', 'good'
  end

  def_fixture :b, dir_name: 'bbb' do
    File.write 'basename', File.basename(Dir.pwd)
  end


  def_fixture :c, cd_into: 'ccc' do
    Dir.mkdir 'ccc'
    File.write 'ccc/blah', '333'
    File.write 'parent', 'good'
  end

  def_fixture(:lazy){ $gu_dynfix_lazy= 'called' }

  #---------------------------------------------------------------------------------------------------------------------

  describe '#def_fixture' do
    it("creates fixtures on-demand, not when defined"){
      $gu_dynfix_lazy.should be_nil
    }

    it("creates fixtures only once"){
      inside_dynamic_fixture(:a){}
      inside_dynamic_fixture(:a){}
      $gu_dynfix_a_count.should == 1
    }

    it("creates the fixture in a directory naming according to the :dir_name option"){
      inside_dynamic_fixture(:b){
        'basename'.should be_file_with_content 'bbb'
      }
    }
  end

  describe '#inside_dynamic_fixture' do
    it("provides a clean copy of the fixture"){
      inside_dynamic_fixture(:b){ File.delete 'basename' }
      inside_dynamic_fixture(:b){ 'basename'.should exist_as_file }
    }

    it("cds into a fixture subdirectory specified by :cd_into"){
      inside_dynamic_fixture(:c){
        File.basename(Dir.pwd).should == 'ccc'
        'blah'.should exist_as_file
      }
    }

    it("provides the full fixture when :cd_into specified"){
      inside_dynamic_fixture(:c){
        '../parent'.should exist_as_file
      }
    }
  end

  #---------------------------------------------------------------------------------------------------------------------


  describe '#run_each_in_dynamic_fixture' do

    context "when only fixture name specified" do
      run_each_in_dynamic_fixture :a
      def test
        'aa/abc'.should exist_as_file
        File.delete 'aa/abc'
      end
      it("provides each example a clean copy of the fixture (1/2)"){ test }
      it("provides each example a clean copy of the fixture (2/2)"){ test }
    end

    context "when :cd_into specified" do
      run_each_in_dynamic_fixture :a, cd_into: 'aa'
      it("runs examples in the specified fixture subdirectory"){
        'abc'.should exist_as_file
      }
      it("provides the full fixture"){
        '../a_parent'.should exist_as_file
      }
    end
  end

end
