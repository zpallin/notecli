
require "spec_helper"
require "pp"
require "fakefs"

History = Note::History

RSpec.describe Note do
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
