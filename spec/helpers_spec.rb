
require "spec_helper"
require "pp"
require "fakefs"

RSpec.describe Helpers do
  include FakeFS::SpecHelpers
  include Helpers
    
  it "process_pages: takes page names as argument and filters them to pages array" do
    FakeFS do
      pages = process_pages ["f1", "f2"]
      expect(pages.first.class).to eq(Page)
      expect(pages.map{|p| p.name}).to eq(["f1", "f2"])
    end
  end
  
  it "process_pages: can take match as a value to run string matches instead" do
    FakeFS do
      pages = process_pages ["f1", "f2"], match: true
      expect(pages).to eq([])

      Page.new "f1"
      Page.new "f2"

      pages = process_pages ["f1", "f2"], match: true
      expect(pages.map{|p| p.name}).to eq(["f1", "f2"])

      pages = process_pages ["f*"], match: true
      expect(pages.map{|p| p.name}).to eq(["f1", "f2"])
    end
  end

  it "page_op: acts like a chef-provider, allows for easy cli command definition" do
    FakeFS do
      page_op :test
    end
  end

  it "page_op: can take multiple paramters, match, verbose, pages, and name" do
    FakeFS do
      page_op :test do
        match true
        verbose true
        pages ["f1", "f2"] 
      end
    end
  end

  it "page_op: can also pass lambdas for :one, :many, and :none pages found" do
    FakeFS do
      expect{
        page_op :test do
          match true
          verbose true
          pages ["f1", "f2"]
          one lambda {|x| puts :one}
          many lambda {|x| puts :many}
          none lambda {|x| puts :none}
        end
      }.to output("no matches ([])\nnone\n").to_stdout

      Page.new "f1"
  
      expect{
        page_op :test do
          match true
          verbose true
          pages ["f1", "f2"]
          one lambda {|x| puts :one}
          many lambda {|x| puts :many}
          none lambda {|x| puts :none}
        end
      }.to output("test: \"f1\"\none\n").to_stdout
      
      Page.new "f2"
      expect{
        page_op :test do
          match true
          verbose true
          pages ["f1", "f2"]
          one lambda {|x| puts :one}
          many lambda {|x| puts :many}
          none lambda {|x| puts :none}
        end
      }.to output("test in order: ([\"f1\", \"f2\"])\nmany\n").to_stdout
    end
  end

end
