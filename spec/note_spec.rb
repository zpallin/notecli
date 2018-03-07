
require "spec_helper"
require "pp"
require "fakefs"

Book		= Note::Book
Page    = Note::Page
Group   = Note::Group
Config  = Note::Config
FileOp  = Note::FileOp
History = Note::History


RSpec.describe Note do
  include FakeFS::SpecHelpers
  include Note

	describe Book do
		it "can be created" do
			FakeFS do
				config = Config.new
				b1 = Book.create "b1"
				expect(b1.path).to eq(File.join(config.namespace_path(b1.name)))
				expect(b1.name).to eq("b1")
			end
			FakeFS.clear!
		end

    it "can check that it exists" do
      FakeFS do
        config = Config.new
        expect(Book::exists? "b1").to be false
        b1 = Book.create "b1"
        expect(Book::exists? "b1").to be true
        expect(b1.exists?).to be true
      end
			FakeFS.clear!
    end

    it "can parse books and pages and derive bookname from path" do
      FakeFS do
        config = Config.new
        bookname = Book::name_from_path("b1/f1")
        expect(bookname).to eq("b1")

        bookname, pagename = Book::bookname_and_pagename("b1/f1")
        expect(Book::exists? bookname).to be false
        expect(Page::exists? pagename).to be false
        expect(bookname).to eq("b1")
        expect(pagename).to eq("f1")

        b1 = Book.create "b1"
        book, page = Book::book_and_page("b1/f1")
        expect(book.exists?).to be true
        expect(page.exists?).to be false
        expect(book.name).to eq("b1")
        expect(page.name).to eq("f1")

        book, pagename = Book::book_and_pagename("b1/f1")
        expect(book.exists?).to be true
        expect(Page::exists? pagename).to be false
        expect(book.name).to eq("b1")
        expect(pagename).to eq("f1")
      end
			FakeFS.clear!
    end

		it "can list all files in its directory" do
			FakeFS do
				config = Config.create
				b1 = Book.create "b1"
				p1 = Page.create "b1/p1"
				expect(b1.list_files).to eq([File.join(config.store_path,"b1","p1")])
				p2 = Page.create "b1/p2"
				expect(b1.list_files).to eq([
					File.join(config.store_path,"b1","p1"),
					File.join(config.store_path,"b1","p2")
				])
			end
			FakeFS.clear!
		end
	
		it "can list its contents as names" do
			FakeFS do
				b1 = Book.create "b1"
				p1 = Page.create "b1/p1"
				p2 = Page.create "b1/p2"
				expect(b1.list_names).to eq(["p1", "p2"])
			end
			FakeFS.clear!
		end
	
		it "can list its contents as pages" do
			FakeFS do
				config = Config.new
				b1 = Book.create "b1"
				p1 = Page.create "b1/p1"
				p2 = Page.create "b1/p2"
				expect(b1.list_pages.map{|x|x.name}).to eq(["p1", "p2"])
			end
			FakeFS.clear!
		end

    it "can search all pages for content" do
      FakeFS do
				b1 = Book.create "b1"
        f1 = Page.create "b1/f1"
        f2 = Page.create "b1/f2"
        f1.write "stuff\nwhee\n"
        f2.write "stuff\n"

        results = b1.search "stuff"
        expect(results.length).to eq(2)
        expect(results[0][:page].name).to eq("f1")
        expect(results[0][:search]).to eq("stuff\n")
        expect(results[0][:line]).to eq(1)
        expect(results[1][:page].name).to eq("f2")
        expect(results[1][:search]).to eq("stuff\n")
        expect(results[1][:line]).to eq(1)

        results = b1.search "whee"
        expect(results.length).to eq(1)
        expect(results[0][:page].name).to eq("f1")
        expect(results[0][:search]).to eq("whee\n")
        expect(results[0][:line]).to eq(2)
      end
      FakeFS.clear!
    end

    it "can assert the path to it exists" do
      FakeFS do
        b1 = Book.new "b1"
        expect(File.directory? b1.path).to be false
        b1.assert
        expect(File.directory? b1.path).to be true
      end
			FakeFS.clear!
    end

		it "can be deleted" do
			FakeFS do
				b1 = Book.create "b1"
				p1 = Page.create "b1/p1"
				expect(b1.list_pages.length).to eq(1)
				b1.delete
				expect(Book.exists? "b1").to eq(false)
			end
			FakeFS.clear!
		end

		it "can match a path" do
			FakeFS do
				b1 = Book.create "b1"
				p1 = Page.create "b1/p1"
				p1 = Page.create "b1/p2"
				contents = Dir["#{b1.path}/p*"].map{|x|x.rpartition("/").last}
				expect(b1.list_names "p*").to eq(contents)
			end
			FakeFS.clear!
		end

    it "can generate paths to its components via courtesy methods" do
      FakeFS do
        config = Config.new
        b1 = Book.create "b1"
        expect(b1.path_to).to eq(config.store_path "b1")
        expect(b1.path_match).to eq(config.store_path "b1/*")
        expect(b1.path_to "test").to eq(config.store_path "b1/test")
        expect(b1.path_match "*test*").to eq(config.store_path "b1/*test*")
      end
      FakeFS.clear!
    end
	end

  describe Group do
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
        f1    = Page.create "f1"
        f2    = Page.create "f2"
        f3    = Page.create "f3"
        expect(group.add([f1, f2])).to eq(true)
        expect(group.add(f3)).to eq(true)
      end
      FakeFS.clear!
    end

    it "can return the members of its group as page objects" do
      FakeFS do
        group = Group.new "testgroup"
        f1    = Page.create "f1"
        f2    = Page.create "f2"

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
    it "can be opened in a temp file with custom extensions" do
      FakeFS do
       f1 = Page.create "f1"
        expect(f1).to receive(:system).with(
          "vi", File.expand_path("~/.notecli/temp/f1.txt"))
        f1.open

        f2 = Page.create "f2"
        expect(f2).to receive(:system).with(
          "vi", File.expand_path("~/.notecli/temp/f2.csv"))
        f2.open(ext: "csv")

        f3 = Page.create "f3"
        expect(f3).to receive(:system).with(
          "nano", File.expand_path("~/.notecli/temp/f3.markdown"))
        f3.open(editor: "nano", ext: "markdown")
      end
      FakeFS.clear!
    end

    it "can open multiple files at once" do
      FakeFS do
        f1 = Page.create "f1"
        f2 = Page.create "f2"
       
        # open_multiple will system call to the temp paths 
        expect(Page).to receive(:system).with("vi #{f1.temp} #{f2.temp}")
        Page::open_multiple([f1, f2])
      end
      FakeFS.clear!
    end

    context "Page::process_pages" do
      it "takes page names as argument and filters them to pages array" do
        FakeFS do
          pages = Page::process_pages ["f1", "f2"]
          expect(pages.first.class).to eq(Page)
          expect(pages.map{|p| p.name}).to eq(["f1", "f2"])
        end
        FakeFS.clear!
      end

      it "can take match as a value to run string matches instead" do
        FakeFS do
          pages = Page::process_pages ["f1", "f2"], match: true
          expect(pages).to eq([])

          Page.create "f1"
          Page.create "f2"

          pages = Page::process_pages ["f1", "f2"], match: true
          expect(pages.map{|p| p.name}).to eq(["f1", "f2"])

          pages = Page::process_pages ["f*"], match: true
          expect(pages.map{|p| p.name}).to eq(["f1", "f2"])
        end
        FakeFS.clear!
      end
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

		it "must be explicitly created or its directories will not appear" do
			FakeFS do
				config = Config.new
				expect(Dir.exists? config.store_path).to eq(false)
			
				config = Config.create
				expect(Dir.exists? config.store_path).to eq(true)
			end
			FakeFS.clear!
		end

		it "can return the store_path with or without added path" do
			FakeFS do
				config = Config.new
				default_path = File.expand_path("~/.notecli")
				expect(config.store_path).to eq(default_path)
				
				new_path = File.join(default_path, "b1")
				expect(config.store_path "b1").to eq(new_path)
			end
      FakeFS.clear!
		end

		it "can set a namespace for reading pages" do
			# this will check if the config has changed to use a particular
			# namespace. The default is empty "".
			FakeFS do
				config = Config.new
				expect(config.namespace).to eq("")
				config.set_namespace("b1")
				expect(config.namespace).to eq("b1/")
			end
      FakeFS.clear!
		end
  end

  describe FileOp do
    it "can be created" do
      FakeFS do
				config = Config.new
        f1 = FileOp.create "f1"
        expect(f1.name).to eq("f1")
        expect(f1.path).to eq(config.store_path("f1"))
        expect(File.file? f1.path).to eq(true)
      end
      FakeFS.clear!
    end

    it "can be symlinked" do
      FakeFS do
        f1 = FileOp.create "f1"
				f2 = FileOp.new "f2"
        f1.symlink(f2.path)
        expect(File.file? f2.path).to eq(true)
      end
      FakeFS.clear!
    end

    it "can be renamed" do
      FakeFS do
        f1 = FileOp.create "f1"
				f2 = FileOp.new "f2" # not created
        expect(f1.rename "f2").to eq(true)
        expect(f1.fullname).to eq("f2")
        expect(f1.name).to eq("f2")
        expect(FileOp.exists? "f1").to eq(false)
        expect(FileOp.exists? "f2").to eq(true)

        # test that we can rename it to a booked 
        expect(f1.rename "test/f1").to eq(true)
        expect(f1.fullname).to eq("test/f1")
        expect(f1.name).to eq("f1")
        expect(FileOp.exists? "test/f1").to eq(true)
        expect(FileOp.exists? "f2").to eq(false)
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

    it "can use exists? to confirm if it exists or not" do
      FakeFS do
        expect(FileOp.exists? "f1").to eq(false)
        FileOp.create "f1"
        expect(FileOp.exists? "f1").to eq(true)
        
        # and an alias
        expect(FileOp.exist? "f2").to eq(false)
        FileOp.create "f2"
        expect(FileOp.exists? "f2").to eq(true)
      end
      FakeFS.clear!
    end



    it "can write a string to a file" do
      f1 = FileOp.create "f1"
			config = Config.create
      f1.write "stuff"
      expect(f1.read).to eq("stuff")
    end
  end

  context "Note::page_op" do
    it "acts like a chef-provider, allows for easy cli command definition" do
      FakeFS do
        page_op :test
      end
    end

    it "can take multiple paramters, match, verbose, pages, and name" do
      FakeFS do
        page_op :test do
          match true
          verbose true
          pages ["f1", "f2"]
        end
      end
    end

    it "can also pass lambdas for :one, :many, and :none pages found" do
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

        Page.create "f1"
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

        Page.create "f2"
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

  describe History do
    it "adds a page to the history" do
      FakeFS do
        f1 = Page.create "f1"
        f2 = Page.create "f2"
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
        f1 = Page.create "f1"
        expect(f1).to receive(:system)
        expect_any_instance_of(History).to receive(:add).with(f1.fullname)
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
          page = Page.create "f#{i}"
          expect(page).to receive(:system)
          page.open
        end

        expect(history.list).to eq(["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10"])

        f11 = Page.create "f11"
        expect(f11).to receive(:system)
        f11.open

        expect(history.list).to eq(["f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11"])
      end
      FakeFS.clear!
    end
  end
end
