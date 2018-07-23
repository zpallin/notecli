require 'fileutils'
require 'deep_merge'
require 'yaml'
require 'notecli/history'

module Note
  ##############################################################################
  # a book is a directory and has specific calls to operate with it
  # - list   : lists all pages
  # - use   : changes the namespace to this book so you do not need to
  class Book
    attr_reader :path, :name

    class << self
      def exists?(name, config: Config.new)
        Dir.exist? config.namespace_path name
      end

      def create(name, config: Config.new)
        b = new name
        b.assert
        b
      end

      def book_and_page(path, config: Config.new)
        bookname, pagename = Book.bookname_and_pagename(path)
        [Book.new(bookname), Page.new(pagename)]
      end

      def book_and_pagename(path, config: Config.new)
        bookname, pagename = Book.bookname_and_pagename(path)
        [Book.new(bookname), pagename]
      end

      def bookname_and_pagename(path, config: Config.new)
        bnpn = path.rpartition('/')
        [bnpn.first, bnpn.last]
      end

      def name_from_path(path, config: Config.new)
        Book.bookname_and_pagename(path).first
      end
    end

    def initialize(name)
      Config.create
      create(name)
    end

    def exists?
      self.class.exists? name
    end

    def list_names(match = '*')
      list_files(match).map { |f| f.rpartition('/').last }
    end

    def list_pages(match = '*', config: Config.new)
      list_files(match).map do |f|
        Page.new [name, f.rpartition('/').last].join('/')
      end
    end

    # lists all of the pages within the book that match the call
    def list_files(match = '*')
      match_str = "#{path}/#{match}"
      Dir[match_str].select { |x| File.file? x }
    end

    # sets a book to the reader namespace so page names do not need to include
    # the book reference
    def use(_name, config: Config.new)
      config.set_namespace name
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

    # expanded path assuming all matches
    def path_match(match = '*')
      File.expand_path(File.join(@path, match))
    end

    # path_match except default is an empty name
    def path_to(name = '')
      path_match(name)
    end

    # does a text search on all child files
    def search(match = '*')
      found = []
      list_pages.each do |f|
        # supposedly will be more memory efficient
        # from The Tin man
        # https://stackoverflow.com/questions/5761348/ruby-grep-with-line-number
        open(f.path) do |r|
          grep = r.each_line
                  .with_index(1)
                  .each_with_object([]) { |i, m| m << i if i[0][match]; }

          unless grep.empty?
            grep.each do |g|
              found << { page: f, search: g.first, line: g.last }
            end
          end
        end
      end
      found || []
     end
  end
end
