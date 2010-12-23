#! /usr/bin/env ruby


require File.dirname(__FILE__) + '/../../../spec_helper'

require 'mocha'
require 'fileutils'

describe "the mkpasswd function" do

  before :each do
    @scope = Puppet::Parser::Scope.new
  end

  it "should exist" do
    Puppet::Parser::Functions.function("mkpasswd").should == "function_mkpasswd"
  end

  it "should raise a ParseError if less than 2 arguments is passed" do
    lambda { @scope.function_mkpasswd(['aaa']) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if there is more than 2 arguments" do
    lambda { @scope.function_mkpasswd(['foo', 'bar','foo']) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the sencond argument is not 8 characters" do
    lambda { @scope.function_mkpasswd(['foo','aaa']) }.should( raise_error(Puppet::ParseError))
  end

  describe "when executing properly" do
    it "should return a salted md5 hash" do
      res = @scope.function_mkpasswd(['foobar','12345678']).should == "$1$12345678$z10EIqhVCcU9.xpb4navW0"
    end

    it "should use the crypt string method" do
      String.any_instance.expects(:crypt).with('$1$' << '12345678' << '$')
      @scope.function_mkpasswd(['foobar','12345678'])
    end
  end
end
