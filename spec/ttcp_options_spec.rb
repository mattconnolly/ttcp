require "rspec"
require 'spec_helper.rb'

TTCP_EXECUTABLE = File.expand_path('../../bin/ttcp', __FILE__)


def test_ttcp(options = '')
  `DRY_RUN=YES #{TTCP_EXECUTABLE} #{options} 2>&1`
end

describe "Command Line Option Parsing" do

  it "ttcp fails without -t or -r" do
    test_ttcp
    $?.should_not == 0
  end

  it "ttcp fails with both -t and -r" do
    test_ttcp '-t -r'
    $?.should_not == 0
  end

  it "ttcp fails without a host with -t" do
    test_ttcp '-t'
    $?.should_not == 0
  end

  it "ttcp is ok with a host and -t" do
    test_ttcp '-t HOST'
    $?.should == 0
  end

  it "ttcp is ok with -r and no host" do
    test_ttcp '-r'
    $?.should == 0
  end

  specify "ttcp prints out the version" do
    version = test_ttcp '--version'
    version.chomp.should == TTCP::VERSION
  end
end
