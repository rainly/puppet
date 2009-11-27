#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe Puppet::Parser::Expression::CaseStatement do
  before :each do
    @scope = Puppet::Parser::Scope.new
  end

  describe "when evaluating" do

    before :each do
      @test = stub 'test'
      @test.stubs(:denotation).returns("value")

      @option1 = stub 'option1', :eachopt => nil, :default? => false
      @option2 = stub 'option2', :eachopt => nil, :default? => false

      @options = stub 'options'
      @options.stubs(:each).multiple_yields(@option1, @option2)

      @casestmt = Puppet::Parser::Expression::CaseStatement.new :test => @test, :options => @options
    end

    it "should evaluate test" do
      @test.expects(:denotation)

      @casestmt.compute_denotation
    end

    it "should scan each option" do
      @options.expects(:each).multiple_yields(@option1, @option2)

      @casestmt.compute_denotation
    end

    describe "when scanning options" do
      before :each do
        @opval1 = stub_everything 'opval1'
        @option1.stubs(:eachopt).yields(@opval1)

        @opval2 = stub_everything 'opval2'
        @option2.stubs(:eachopt).yields(@opval2)
      end

      it "should evaluate each sub-option" do
        @option1.expects(:eachopt)
        @option2.expects(:eachopt)

        @casestmt.compute_denotation
      end

      it "should evaluate first matching option" do
        @opval2.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)
        @option2.expects(:denotation)

        @casestmt.compute_denotation
      end

      it "should evaluate_match with sensitive parameter" do
        Puppet.stubs(:[]).with(:casesensitive).returns(true)
        @opval1.expects(:evaluate_match).with { |*arg| arg[2][:sensitive] == true }

        @casestmt.compute_denotation
      end

      it "should return the first matching evaluated option" do
        @opval2.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)
        @option2.stubs(:denotation).returns(:result)

        @casestmt.compute_denotation.should == :result
      end

      it "should evaluate the default option if none matched" do
        @option1.stubs(:default?).returns(true)
        @option1.expects(:denotation)

        @casestmt.compute_denotation
      end

      it "should return the default evaluated option if none matched" do
        @option1.stubs(:default?).returns(true)
        @option1.stubs(:denotation).returns(:result)

        @casestmt.compute_denotation.should == :result
      end

      it "should return nil if nothing matched" do
        @casestmt.compute_denotation.should be_nil
      end

      it "should match and set scope ephemeral variables" do
        @opval1.expects(:evaluate_match).with { |*arg| arg[0] == "value" }

        @casestmt.compute_denotation
      end

      it "should evaluate this regex option if it matches" do
        @opval1.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)

        @option1.expects(:denotation)

        @casestmt.compute_denotation
      end

      it "should return this evaluated regex option if it matches" do
        @opval1.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)
        @option1.stubs(:denotation).returns(:result)

        @casestmt.compute_denotation.should == :result
      end

      it "should unset scope ephemeral variables after option evaluation" do
        @opval1.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)
        @option1.stubs(:denotation).returns(:result)

        @scope.expects(:unset_ephemeral_var)

        @casestmt.compute_denotation
      end

      it "should not leak ephemeral variables even if evaluation fails" do
        @opval1.stubs(:evaluate_match).with { |*arg| arg[0] == "value" }.returns(true)
        @option1.stubs(:denotation).raises

        @scope.expects(:unset_ephemeral_var)

        lambda { @casestmt.compute_denotation }.should raise_error
      end
    end

  end
end