
require "spec_helper"
require "pp"
require "fakefs"

Page    = Note::Page
Group   = Note::Group
Config  = Note::Config
FileOp  = Note::FileOp
History = Note::History

RSpec.describe Note do
  describe Group do
    include FakeFS::SpecHelpers
    
    it "can be created" do
      FakeFS do
        group = Group.new "testgroup"
        expect(group.name).to eq("testgroup")
        expect(group.path).to eq(Group::path_to "testgroup")
        expect(File.directory? group.path).to eq(true)
      end
      FakeFS.clear!
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
      FakeFS.clear!
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
      FakeFS.clear!
    end

    it "can rename the group" do
      FakeFS do
        group = Group.new "testgroup"
        expect(group.rename "newname").to eq(true)
        expect(group.name).to eq("newname")
        expect(File.directory? Group::path_to("newname")).to eq(true)
      end 
      FakeFS.clear!
    end 
  end

  describe Page do
    include FakeFS::SpecHelpers
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
      FakeFS.clear!
    end

    it "can open multiple files at once" do
      FakeFS do
        f1 = Page.new "f1"
        f2 = Page.new "f2"
       
        # open_multiple will system call to the temp paths 
        expect(Page).to receive(:system).with("vi #{f1.temp} #{f2.temp}")
        Page::open_multiple([f1, f2]) 
      end
      FakeFS.clear!
    end
  end

  describe Config do
    it "can load its configuration from file" do
      FakeFS do
        config = Config.new
        expect(!!config).to eq(true)
      end
      FakeFS.clear!
    end
  end

  describe FileOp do
    include FakeFS::SpecHelpers
    
    it "can be created" do
      FakeFS do
        f1 = FileOp.new "f1"
        expect(f1.name).to eq("f1")
        expect(f1.path).to eq(FileOp::path_to "f1")
        expect(File.file? f1.path).to eq(true)
      end
      FakeFS.clear!
    end

    it "can find files within its pages dir" do
      FakeFS do
        f1 = FileOp.new "f1"
        f2 = FileOp.new "f2"
        f3 = FileOp.new "f3"
        expect(FileOp::find_path("*")).to eq([f1.path, f2.path, f3.path])
        expect(FileOp::find_path("*1")).to eq([f1.path])
        expect(FileOp::find("*").map{|f|f.name}).to eq([f1.name, f2.name, f3.name])
        expect(FileOp::find("something").map{|f|f.name}).to eq([])
      end
      FakeFS.clear!
    end
    
    it "can be symlinked" do
      FakeFS do
        f1    = FileOp.new "f1"
        path  = FileOp::path_to "f2"
        f1.symlink(path)
        expect(File.file? path).to eq(true)
      end
      FakeFS.clear!
    end

    it "can be renamed" do
      FakeFS do
        f1 = FileOp::new "f1"
        expect(f1.rename "f2").to eq(true)
        expect(f1.name).to eq("f2")
        expect(File.file? FileOp::path_to("f2")).to eq(true)
      end
      FakeFS.clear!
    end

    it "can be appended, prepended, and read to a string" do
      FakeFS do
        f1 = FileOp::new "f1"
        f1.append "test\n"
        f1.append "test2\n"
        f1.prepend "test3\n"
        expect(f1.read).to eq("test3\ntest\ntest2\n")
      end
      FakeFS.clear!
    end
  end

  describe History do
    it "adds a page to the history" do
      FakeFS do
        f1 = Page.new "f1"
        f2 = Page.new "f2"
        history = History.new
        history.add f1
        history.add f2

        expect(history.list).to eq(["f1", "f2"])
      end
      FakeFS.clear!
    end
    
    it "will try to create the ~/.notecli/history file if it does not exist" do
      FakeFS do
        expect(File.exists? "~/.notecli/history").to eq(false)
        history = History.new
        expect(File.exist? history.path).to eq(true)
      end
      FakeFS.clear!
    end

    it "can add a page to its history, taking its name or string as an argument" do
      FakeFS do
        history = History.new
        f1 = Page.new "f1"
        expect(f1).to receive(:system)
        expect_any_instance_of(History).to receive(:add).with(f1.name)
        f1.open
      end
      FakeFS.clear!
    end

    it "controls line numbers via config" do
      FakeFS do
        history = History.new
        expect(File.exist? history.path).to eq(true)
        expect(history.list).to eq([])

        config = Config.new
        config.set("history_size", 10)
        expect(config.settings["history_size"]).to eq(10)
      
        for i in 1...config.settings["history_size"]+1 do
          page = Page.new "f#{i}"
          expect(page).to receive(:system)
          page.open
        end

        expect(history.list).to eq(["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10"])

        f11 = Page.new "f11"
        expect(f11).to receive(:system)
        f11.open

        expect(history.list).to eq(["f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11"])
      end
      FakeFS.clear!
    end
  end
end
