
require "fileutils"
require "deep_merge"
require "yaml"

module Note
  ############################################################################## 
  # a page is a file, no less. This class contains to means to crud a file
  # more or less. Called a page to avoid name confict
  #
  # this class operates to interaction with the file structure, does not store
  # any state data.
  class Page
    attr_reader :name, :path
    
    def initialize(name, config: Config.new)
			@config = config.settings
      self.create name
    end

    # returns the correct path to the page storage dir
    def self.path_to(pagename="", config: Config.new)
      File.expand_path File.join(config.settings["pages_path"], pagename)
    end

    # asserts that the page storage path exists
    def self.assert
      FileUtils.mkdir_p Page::path_to
    end

    # returns page objects for each matching page name
    def self.find(match="*")
      Page::find_path(match).map{|f| Page.new File.basename(f)}
    end

    # returns full paths for each matching page name
    def self.find_path(match="*")
      Dir[(Page::path_to match)]
    end

    def self.search(match="*")
      found = []
      self::find.each do |page|
        # supposedly will be more memory efficient
        open(page.path) do |f|

          # from The Tin man
          # https://stackoverflow.com/questions/5761348/ruby-grep-with-line-number
          grep = f.each_line.with_index(1).inject([]) { |m,i| m << i if (i[0][match]); m }

          if grep.length > 0
            grep.each do |g|
              found << {page: page, grep: g.first, line: g.last}
            end
          end
        end
      end
      return found || []
    end

    # creates a symlink to another path for the original path of
    # this page
    def symlink(to_path)
      FileUtils.rm to_path if File.exist? to_path 
      FileUtils.ln_s(@path, to_path)
    end

    # runs all of the creation steps for the page dir
    def create(name)
      Page::assert
      @name = name
      @path = Page::path_to name
      FileUtils.mkdir_p File.dirname(@path)
      FileUtils.touch(@path)
    end

    # opens a file with the editor and file type provided
    # a file is symlinked to a tmp directory and opened with 
    # a different file extension
    def open(editor: @config["editor"], ext: @config["ext"])
      Page::assert
      temp = self.temp ext
      system(editor, temp)
      self.rm_temp ext
    end

    def self.open_multiple(pages, 
                           editor: @config["editor"], 
                           ext: @config["ext"])
      Page::assert
      temps = pages.map{|page| page.temp ext}
      conns = "#{editor} #{temps.join(' ')}"
      system(conns)
      #system(editor, temps.join(' '))
      pages.map{|page| page.rm_temp ext}
    end

    # creates a symlink in a temp directory
    def temp(ext, parent: @config["temp_path"])
      to_path = File.join(parent, @name + "." + ext)
      FileUtils.mkdir_p parent
      self.symlink to_path
      to_path
    end

    # removes a temp file after it is created
    def rm_temp(file_ext, parent: @config["temp_path"])
      FileUtils.rm File.join(parent, @name + ".#{file_ext}")
    end

    # renames a file to a new name and checks if a file
    # exists first 
    def rename(name)
      FileUtils.mv @path, Page::path_to(name)
      self.create name
      return true
    end

    # delete the page
    def delete
      FileUtils.rm @path
    end

    # appends the file content with a string
    def append(string)
      File.open(@path, "a") do |file|
        file.write string
      end
    end

    # prepends the top of a note with a new line
    def prepend(string)
			File.open(@path, "r") do |orig|
					File.unlink(@path)
					File.open(@path, "w") do |new|
							new.write string
							new.write orig.read()
					end
			end
    end

    # returns file contents as string
    def read
      file = File.open(@path)
      file.read
    end
  end
end
