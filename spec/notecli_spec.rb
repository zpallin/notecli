
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
    context "open" do
      it "can open a file" do
        FakeFS do
          allow(Page).to receive_messages(:open => "hello")
          f1 = Page.create "f1"
          conf = Config.new
          
          # because Page is being called as a static method
          expect(subject).to receive(:page_op).with(:open)
          
          data = capture(:stdout){ subject.open("f1") }
        end
      end
      it "can open with a different editor or file extension" do
        FakeFS do
          conf = Config.new
          conf.set "editor", "nano"
          conf.set "ext", "md"
          f1 = Page.create "f1"
          expect(f1).to receive(:system).with(
            "nano", 
            File.expand_path(File.join("~",".notecli","temp","f1.md")))
          f1.open
        end
      end
      it "can open files matching a basic string match" do
        FakeFS do
          f1 = Page.create "f1"
          f2 = Page.create "f2"
        end
      end
    end

    context "groups" do
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
      it "can also list contents of each group with a flag" do
        FakeFS do
          test1 = Group.new "test1"
          test2 = Group.new "test2"
          f1 = Page.create "f1"
          f2 = Page.create "f2"
          f3 = Page.create "f3"
          
          test1.add f1
          test2.add f2
          test2.add f3

          subject.options = {:'with-contents' => true }
          data = capture(:stdout) { subject.groups }
          expect(data).to eq(
            "list all groupings with match \".*\"\n---\ntest1:\n- f1\ntest2:\n- f2\n- f3\n")
        end
      end
    end
    context "rename" do
      it "can rename a page" do
        FakeFS do
          p1 = Page.create "p1"
          p2 = Page.new "p2"
          expect(Page.exists? "p1").to eq(true)
          expect(Page.exists? "p2").to eq(false)

          subject.options = {}
          data = capture(:stdout) {subject.rename "p1", "p2"}
          expect(data).to eq("\"p1\" renamed to \"p2\"\n")
          expect(Page.exists? "p1").to eq(false)
          expect(Page.exists? "p2").to eq(true)
        end
      end

      it "can force rename a page" do
        FakeFS do
          p1 = Page.create "p1"
          p2 = Page.create "p2"
          expect(Page.exists? "p1").to eq(true)
          expect(Page.exists? "p2").to eq(true)

          subject.options = {:force => true}
          data = capture(:stdout) {subject.rename "p1", "p2"}
          expect(data).to eq("\"p1\" renamed to \"p2\"\n")
          expect(Page.exists? "p1").to eq(false)
          expect(Page.exists? "p2").to eq(true)
        end
      end
    end
  end
end

