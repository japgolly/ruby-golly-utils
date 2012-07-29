# encoding: utf-8
require_relative '../bootstrap/spec'
require 'tmpdir'
require 'golly-utils/child_process'
require 'golly-utils/testing/rspec/within_time'

describe GollyUtils::ChildProcess do
  after :each do
    cp.shutdown
  end

  let(:cp){
    described_class.new \
      quiet: true,
      start_command: "#{File.expand_path '../child_process_mock_target.rb', __FILE__} #{tmpfile}"
  }
  let(:tmpfile){
    "#{Dir.tmpdir}/live_tester-#{Time.now.strftime '%Y%m%d%H%M%S%L'}-#{$$}.tmp"
  }

  it("shall start and stop server processes"){
    cp.startup
    within(2).seconds{ File.exists?(tmpfile).should == true }
    cp.alive?.should == true
    cp.shutdown.should == true
    within(2).seconds{ File.exists?(tmpfile).should == false }
    cp.alive?.should == false
  }

  it("shall do nothing when startup called and already started"){
    cp.startup
    (pid= cp.pid).should_not be_nil
    cp.startup
    cp.pid.should == pid
  }

  it("shall do nothing when shutdown called and not started"){
    cp.alive?.should == false
    cp.shutdown.should == true # mostly just asserting it doesn't fail
  }
end
