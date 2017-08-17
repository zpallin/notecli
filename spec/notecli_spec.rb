
require "spec_helper"
require "pp"
require "fakefs"
require "notecli/cli"
require "notecli/version"
require "notecli/page"
require "notecli/group"
require "notecli/config"

Link = Notecli::Link
CLI = Notecli::CLI

RSpec.describe Notecli do
  it "has a version number" do
    expect(Notecli::VERSION).not_to be nil
  end

  describe CLI do
    context "groups" do
      let(:output_find) {capture(:stdout) {subject.find}}
      it "can list all of the current groups" do
        FakeFS do
          Group.new "test1"
          Group.new "test2"
          data = capture(:stdout) { subject.groups }
          expect(data).to eq(
            "list all groupings with match \".*\"\n---\n- test1\n- test2\n")
        end
      end
      it "can match groupings and list them" do
        FakeFS do 
          Group.new "test1"
          Group.new "test2"
          data = capture(:stdout) { subject.groups "test*" }
          expect(data).to eq(
            "list all groupings with match \"test*\"\n---\n- test1\n- test2\n")
        end
      end
    end
  end
end

