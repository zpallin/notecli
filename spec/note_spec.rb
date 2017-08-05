
require "spec_helper"
require "pp"
require "fakefs"

Page    = Note::Page
Group   = Note::Group
Config  = Note::Config

RSpec.describe Note do
  describe Group do
    include FakeFS::SpecHelpers
    
    it "can be created" do
      FakeFS.activate!
        group = Group.new "testgroup"
        expect(group.name).to eq("testgroup")
        expect(group.path).to eq(Group::path_to "testgroup")
        expect(File.directory? group.path).to eq(true)
      FakeFS.deactivate!
    end

    it "can add a page to its group" do
      FakeFS do
        group = Group.new "testgroup"
        f1    = Page.new "f1"
        f2    = Page.new "f2"
        f3    = Page.new "f3"
        expect(group.add([f1, f2])).to eq(true)
        expect(group.add(f3)).to eq(true)
      end
    end

    it "can return the members of its group as page objects" do
      FakeFS do
        group = Group.new "testgroup"
        f1    = Page.new "f1"
        f2    = Page.new "f2"

        group.add([f1, f2])
        members = group.members
        expect(members[0].name).to eq(f1.name)
        expect(members[0].path).to eq(f1.path)
        expect(members[1].name).to eq(f2.name)
        expect(members[1].path).to eq(f2.path)
      end
    end

    it "can rename the group" do
      FakeFS do
        group = Group.new "testgroup"
        expect(group.rename "newname").to eq(true)
        expect(group.name).to eq("newname")
        expect(File.directory? Group::path_to("newname")).to eq(true)
      end 
    end 
  end

  describe Page do
    include FakeFS::SpecHelpers
    it "can be created" do
      FakeFS do
        f1 = Page.new "f1"
        expect(f1.name).to eq("f1")
        expect(f1.path).to eq(Page::path_to "f1")
        expect(File.file? f1.path).to eq(true)
      end
    end

    it "can find files within its pages dir" do
      FakeFS do
        f1 = Page.new "f1"
        f2 = Page.new "f2"
        f3 = Page.new "f3"
        expect(Page::find_path("*")).to eq([f1.path, f2.path, f3.path])
        expect(Page::find_path("*1")).to eq([f1.path])
        expect(Page::find("*").map{|f|f.name}).to eq([f1.name, f2.name, f3.name])
        expect(Page::find("something").map{|f|f.name}).to eq([])
      end
    end

    it "can be symlinked" do
      FakeFS do
        f1    = Page.new "f1"
        path  = Page::path_to "f2"
        f1.symlink(path)
        expect(File.file? path).to eq(true)
      end
    end

    it "can be opened in a temp file with custom extensions" do
      FakeFS do
        f1 = Page::new "f1"
        expect(f1).to receive(:system).with(
          "vi", File.expand_path("~/.notecli/temp/f1.txt"))
        f1.open

        f2 = Page::new "f2"
        expect(f2).to receive(:system).with(
          "vi", File.expand_path("~/.notecli/temp/f2.csv"))
        f2.open(ext: "csv")

        f3 = Page::new "f3"
        expect(f3).to receive(:system).with(
          "nano", File.expand_path("~/.notecli/temp/f3.markdown"))
        f3.open(editor: "nano", ext: "markdown")
      end
    end

    it "can be renamed" do
      FakeFS do
        f1 = Page::new "f1"
        expect(f1.rename "f2").to eq(true)
        expect(f1.name).to eq("f2")
        expect(File.file? Page::path_to("f2")).to eq(true)
      end
    end

    it "can be appended, prepended, and read to a string" do
      FakeFS do
        f1 = Page::new "f1"
        f1.append "test\n"
        f1.append "test2\n"
        f1.prepend "test3\n"
        expect(f1.read).to eq("test3\ntest\ntest2\n")
      end
    end
  end

  describe Config do
    it "can load its configuration from file" do
      FakeFS do
        config = Config.new
        expect(!!config).to eq(true)
      end
    end
  end
end

