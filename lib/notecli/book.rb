
require "fileutils"
require "deep_merge"
require "yaml"
require "notecli/history"

module Note
  ##############################################################################  
	# a book is a directory and has specific calls to operate with it
	# - list 	: lists all pages
	# - use 	: changes the namespace to this book so you do not need to
	class Book
		attr_reader :path, :name

		class << self
			def exists?(name, config: Config.new)
				Dir.exists? config.namespace_path name
			end

			def create(name, config: Config.new)
				b = self.new name
				b.assert
				b
			end
    
      def book_and_page(path, config: Config.new)
        bookname, pagename = Book::bookname_and_pagename(path)
        [ Book::new(bookname), Page::new(pagename) ]
      end

      def book_and_pagename(path, config: Config.new)
        bookname, pagename = Book::bookname_and_pagename(path)
        [ Book::new(bookname), pagename ]
      end

      def bookname_and_pagename(path, config: Config.new)
        bnpn = path.rpartition('/')
        [ bnpn.first, bnpn.last ]
      end

      def name_from_path(path, config: Config.new)
        Book::bookname_and_pagename(path).first
      end
		end

		def initialize(name)
			Config.create
			self.create(name)
		end

    def exists?
      self.class.exists? self.name
    end

		def list_names(match="*")
			list_files(match).map{|f|f.rpartition('/').last}
		end

		def list_pages(match="*", config: Config.new)
			list_files(match).map{|f|
				Page.new [self.name, f.rpartition("/").last].join("/")
			}
		end

		# lists all of the pages within the book that match the call
		def list_files(match="*")
			match_str = "#{self.path}/#{match}"
			Dir[match_str]
		end

		# sets a book to the reader namespace so page names do not need to include
		# the book reference
		def use(name, config: Config.new)
			config.set_namespace self.name
		end

		# create a book with name
		def create(name, config: Config.new)
			@name = name
			@path = config.namespace_path(name)
		end

		# make sure the full path to the file exists
		def assert
			FileUtils.mkdir_p @path
		end

		# delete all content
		def delete
			FileUtils.rm_r @path
		end

		def path_match(match="*") 
			File.expand_path(File.join(self.path, match))
		end

		# returns full path of expected path based on book path
		# ergonomically
		def path_to(name="")
			File.expand_path(File.join(@path, name))
		end

	 	def search(match="*")
			found = []
			self.list_pages.each do |f|
				# supposedly will be more memory efficient
				# from The Tin man
				# https://stackoverflow.com/questions/5761348/ruby-grep-with-line-number
				open(f.path) do |r|
					grep = r.each_line
									.with_index(1)
									.inject([]) { |m,i| m << i if (i[0][match]); m }

					grep.each do |g|
						found << {name: f.name, search: g.first, line: g.last}
					end if grep.length > 0
				end
			end
			return found || []
		end
	end
end
