require "spec_helper"

RSpec.describe Note do
  describe Note::Group do
    include FakeFS::SpecHelpers
    
    it "can be created" do
      FakeFS.activate!
      group = Note::Group.new "testgroup", "~/.notecli"
      expect(group.create).to eq([File.expand_path("~/.notecli/groups/testgroup")])
      FakeFS.deactivate!
    end

    it "can add a file to its group" do
      FakeFS.activate!
      home = File.expand_path "~/.notecli"
      FileUtils.mkdir_p("#{home}/pages")
      group = Note::Group.new "testgroup", "#{home}"
      f1 = Note::Page.new "#{home}/pages/f1"
      f2 = Note::Page.new "#{home}/pages/f2"
      expect(group.add([f1, f2])).to eq([])
      FakeFS.deactivate!

    end

  end
  describe Note::Page do

  end
  describe Note::Config do
    it "can load its configuration from file" do
      config = Note::Config.new
      expect(!!config).to eq(true)
    end
  end
end

