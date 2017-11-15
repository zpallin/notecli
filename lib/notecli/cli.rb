
require 'thor'
require 'notecli/config'
require 'notecli/group'
require 'notecli/page'
require 'notecli/book'
require 'notecli/version'
require "highline/import"

module Notecli

	##############################################################################
	# books are used to categorize pages
	class Book < Thor
	include Note
#		desc "list MATCH [MATCH...]", "lists all book names that match"
#		def list(*books)
#				
#		end

    ############################################################################ 
    # show contents of a book
		desc "show NAME", "show all pages of a book"
    option :'fullpath',
           :type => :boolean,
           :aliases => [:'-u']
		def show(name)
			if Note::Book.exists? name
				book = Note::Book.new name
				if options[:fullpath]
					book.list_files.each do |path|
						puts path
					end
				else
					book.list_names.each do |name|
						puts name
					end
				end
			else
				puts "Book \"#{name}\" does not exist"
			end
		end
	end

  ############################################################################## 
	# used to link pages and groups together
	class Link < Thor
  include Note
		desc "groups MATCH [MATCH...] --to-page PAGE", "links groups to a page"
		option :"to-page", :type => :string
		def groups(*args)
			pageName = options[:"to-page"]
			if pageName
				puts "linking #{pageName} to:"
				page = Page.create pageName
				args.each do |groupName|
          puts " - #{groupName}"
					group = Group.new groupName
					group.add page
				end
			else
				say "Must use flag \"--to-page\""
			end
		end

    ############################################################################ 
		desc "pages MATCH [MATCH...] --to-group GROUP", "links pages to a group"
		option :"to-group", :type => :string
		def pages(*args)
			groupName = options[:"to-group"]
			if groupName
				puts "linking #{groupName} to:"
        group = Group.new groupName
		    args.each do |pageName|
          puts " - #{pageName}"
          page = Page.create pageName
          group.add page
        end    
			else
				say "Must use flag \"--to-group\""
			end
		end
	end

  ##############################################################################
  class CLI < Thor
  include Note
    config = Config.new

		desc "groups [GROUP]", "lists all groups, or what groups match"
    option :'with-contents',
           :type => :boolean,
           :default => false,
           :aliases => [:'-w']
		def groups(match=".*")
			if match
				say "list all groupings with match \"#{match}\""
			else
				say "list all groupings"
			end

      if options[:'with-contents']
        puts Group::list_contents(match).to_yaml
      else
        puts Group::list(match).to_yaml
      end
		end

    no_commands do
        end

    ############################################################################   
    # opens one or more files inside notecli
    desc "open PAGE", "opens a page by name or name match"
    option :'match', 
           :type => :boolean, 
           :default => false
    option :editor, 
           :type => :string, 
           :default => config.settings["editor"],
           :aliases => [:'-e']
    option :ext, 
           :type => :string, 
           :default => config.settings["ext"],
           :aliases => [:'-x']
    option :verbose,
           :type => :boolean,
           :aliases => [:'-v'],
           :default => false
    def open(*args)
      puts args 
      ops = options
      page_op :open do
        match ops[:match]
        pages args
        verbose ops[:verbose]

        many lambda { |pages| 
          page_open_multiple pages, ext: ops[:ext], editor: ops[:editor]
        }

        one lambda { |pages|
          pages.first.open editor: ops[:editor], ext: ops[:ext]
        }

        none true
      end

    end
    map "o" => :open
    
    ############################################################################
    # prepends a file
    desc "prepend PAGE", "prepends a page"
    option :'match',
           :type => :boolean,
           :default => false
    option :verbose,
           :type => :boolean,
           :aliases => [:'-v'],
           :default => false
    option :with,
           :type => :string,
           :aliases => [:'-w'],
           :required => true
    option :newline,
           :type => :boolean,
           :aliases => [:'-n'],
           :default => false
    def prepend(*args)
      ops = options
      nl = ops[:newline]? "\n" : ""
      
      page_op :prepend do
        match ops[:match]
        pages args
        verbose ops[:verbose]

        many lambda { |page|
          page.prepend "#{ops[:with]}#{nl}"
        }

        one lambda { |pages|
          pages.first.prepend "#{ops[:with]}#{nl}"
        }

        none true
      end
    end
    map "p" => :prepend

    ############################################################################
    # appends a file
    desc "append PAGE", "appends a page"
    option :'match',
           :type => :boolean,
           :default => false
    option :verbose,
           :type => :boolean,
           :aliases => [:'-v'],
           :default => false
    option :with,
           :type => :string,
           :aliases => [:'-w'],
           :required => true
    option :newline,
           :type => :boolean,
           :aliases => [:'-n'],
           :default => false
    def append(*args)
      ops = options
      nl = ops[:newline]? "\n" : ""

      page_op :append do
        match ops[:match]
        pages args
        verbose ops[:verbose]

        many lambda { |pages|
          pages.each do |page|
            page.append "#{nl}#{ops[:with]}"
          end
        }

        one lambda { |pages|
          pages.first.append "#{nl}#{ops[:with]}"
        }

        none true
      end
    end
    map "a" => :append


    ############################################################################
    # reads out a files content to stdout
    desc "read PAGE", "read a page"
    option :'match',
           :type => :boolean,
           :default => false
    option :verbose,
           :type => :boolean,
           :aliases => [:'-v'],
           :default => false
    def read(*args)
      ops = options

      page_op :read do
        match ops[:match]
        pages args
        verbose ops[:verbose]

        many lambda { |pages|
          pages.each do |pages|
            puts pages.read
          end
        }

        one lambda { |pages|
          puts pages.first.read
        }

        none true
      end
    end
    map "r" => :read
   
    ############################################################################
    # find
    desc "find \"MATCH\"", "finds files with matching names"
    option :full_path, 
           :default => false,
           :type => :boolean,
           :aliases => [:'-p']
    def find(match="*")
      say "Find files matching this name: /#{match}/"
      if options[:full_path]
        puts Page::find_path(match).map{|page| page.path}
      else
        puts Page::find(match).map{|page| page.name}
      end
    end
    map "f" => :find

    ############################################################################
    desc "search REGEX", "finds files with matching data"
    def search(match)
      say "Match for this string: /#{match}/"
      path_parsed = match.rpartition('/')
      submatch = path_parsed.last
      book = Note::Book.create (path_parsed.length > 1 ? path_parsed.first : "")

      res = book.search(submatch)

      res.each do |r|
        puts "#{r[:page].name}:#{r[:line]} -> #{r[:grep]}"
      end
    end
    map "s" => :search

    ############################################################################
    desc "config [KEY=VALUE ...]", 
         "set config keys on the command line (nesting works)"
    def config(key=nil, value=nil)
      conf = Config.new
      if value
        say "setting #{key} to #{value}"
        conf.set(key, value)
      elsif key
        puts "#{conf.settings[key]}"
      else
        puts conf.settings.to_yaml
      end
    end
    map "c" => :config

    ############################################################################
    
    desc "rm MATCH",
         "removes a file with name match"
    option :force,
           :type => :boolean,
           :aliases => [:'-f']
    def rm(match)
      Page::find(match).each do |page|
        if !options[:force]
          delete = ask "Delete #{page.name}? (y/n)"
          next if delete.downcase != "y"
        end
        page.delete
      end
    end

    ############################################################################
    desc "rmg MATCH",
         "removes a group with name match"
    option :'force',
           :type => :boolean,
           :aliases => [:'-f']
    def rmg(match)
      Group::find(match).each do |group|
        if !options[:force]
          delete = ask "Delete #{group.name}? (y/n)"
          next if delete.downcase != "y"
        end
        group.delete
      end
    end
    ############################################################################
    desc "import FILE [FILE...]",
         "import multiple files into notecli"
    option :prefix,
           :type => :string,
           :aliases => [:'-p']
    option :suffix,
           :type => :string,
           :aliases => [:'-s']
    option :rename,
           :type => :string,
           :aliases => [:'-r']
    option :force,
           :type => :boolean,
           :default => false,
           :aliases => [:'-f']
    def import(*files)
      files.each do |file|
        pagename = File.basename(file)

        if options[:rename]
          pagename = options[:rename]
        end

        pagename = options[:prefix] + pagename if options[:prefix]
        pagename = pagename + options[:suffix] if options[:suffix]

        if not options[:force] and Page::exists? pagename
          puts "Page \"#{pagename}\" already exists"
          next
        end

        page = Page.create pagename
        data = File.open(file).read
        page.append(data)
      end
    end

		desc "books MATCH", "lists all books in a namespace"
		def books(match="*")
			matchParsed = match.rpartition('/')
			bookName = matchParsed.length > 1 ? matchParsed.first : ""

			if not Note::Book.exists? bookName
				puts "Book \"#{bookName}\" does not exist"
			else
				parentBook = Note::Book.new bookName
				matchString = File.expand_path(File.join(parentBook.path, matchParsed.last))
				Dir[matchString].select{|f|
					fn = f.rpartition('/').last
					File.directory? f and !(fn =='.' || fn == '..')
				}.each do |book|
					puts book.rpartition('/').last
				end
			end
		end
 
    desc "rename OLDPATH NEWPATH", "rename a page"
    option :force,
           :type => :boolean,
           :default => false,
           :aliases => [:'f']
    def rename(oldname, newname)
      if Page.exists? oldname
        overwrite = nil

        if not options[:force] and Page.exists? newname
          puts "Page \"#{newname}\" exists already.\rOverwrite? (y/n)"
          overwrite = gets.chomp.downcase
        end

        if overwrite == "y" or options[:force] or not Page.exists? newname
          Page.new(oldname).rename newname
          puts "\"#{oldname}\" renamed to \"#{newname}\""
        end
      else
        puts "Page \"#{oldname}\" does not exist"
      end
    end
    ############################################################################ 
    # version
    desc "version", "displays current version"
    def version
      puts Notecli::VERSION
    end
    map "v" => :version
  
    ############################################################################ 
    # linking for groups
		desc "link SUBCOMMAND [OPTIONS]", "used to link groups and pages"
		subcommand :link, Link
		map "l" => :link

    ############################################################################ 
    # book command for managing books
		desc "book SUBCOMMAND [OPTIONS]", "book management commands"
		subcommand :book, Book
		map "b" => :book
  end
end
