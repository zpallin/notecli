require "spec_helper"

RSpec.describe Note do
  describe Note::Group do
    include FakeFS::SpecHelpers
    it "can be created" do
      FakeFS.activate!
      group = Note::Group.new "testgroup", "/var/notecli/groups"
      FakeFS.deactivate!
      expect(group.create).to eq(true)
    end

    it "can add a file to its group" do
      FakeFS.activate!
      group = Note::Group.new "testgroup", "/var/notecli/groups"
      FakeFS.deactivate!
      expect(group.add "filename").to eq(true)
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

