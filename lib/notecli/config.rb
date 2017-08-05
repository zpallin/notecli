
require "fileutils"
require "deep_merge"
require "yaml"

module Note
  ##############################################################################  
  # a group is a data struture that references a directory of symlinked files. 
  # all files are originally stored in the same directory and symlinked so that
  # they may belong to multiple groups.
  #
  # this class operates to interaction with the file structure, does not store
  # any state data.
  class Group
    attr_reader :name, :path

    def initialize(name, config: Config.new)
			@config = config.settings
      self.create name
    end

    def self.path_to(groupname="", config: Config.new)
      File.expand_path File.join(config.settings["groups_path"], groupname)
    end

    def self.assert
      FileUtils.mkdir_p Group::path_to
    end

    # returns the dir -- automatically creates it if not done
    def create(name)
      Group::assert
      @name = name
      @path = Group::path_to name
      FileUtils.mkdir_p @path
    end

    def add(pages)
      [pages].flatten.each do |page|
        return false if not page.symlink File.join(@path, page.name)
      end
      return true
    end

    def members
      entries = Dir.entries(@path).select { |f| File.file?(Page::path_to f) }
      return entries.map{|name| Page.new name}
    end

    def rename(name)
      FileUtils.mv @path, Group::path_to(name)
      self.create name
      return true
    end
  end

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

    # returns page objects for each regex matching page name
    def self.find(match="*", exists=false)
      Page::find_path(match).map{|f| Page.new File.basename(f)}
    end

    # returns full paths for each regex matching page name
    def self.find_path(match="*", exists=false)
      Dir[(Page::path_to match)]
    end

    # creates a symlink to another path for the original path of
    # this page
    def symlink(to_path)
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
    # a file is symlinked to a tmp directory and opened with a different file extension
    def open(editor: @config["editor"], ext: @config["ext"])
      Page::assert
      temp = self.temp ext
      system(editor, temp)
      self.rm_temp ext
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

  ##############################################################################
  # contains methods that analyze note layout
  class Info
    def self.list_groups(groups=[], config: Config.new)
      Group::assert

      all_groups = Dir.entries(Group::path_to).reject{|g|  g =~ /^\.\.?$/}
      if groups.length == 0
        all_groups
      else
        all_groups.select{|g| groups.include? File.basename(g)}
      end
    end
  end

  ############################################################################## 
  # config merges default configuration and local configuration on top.
  # You cannot change default config, and all config changes are stored in 
  # ~/.notecli.yml, for now, meaning that there are no global changes yet.
  # Only changes for local users.
  class Config
		attr_accessor :settings

    def initialize
      user_home = File.expand_path("~")
      @settings = Config::default
      @files = ["#{user_home}/.notecli/config.yml"]
      self.load
    end

    def self.default
      {
        "last_updated" => DateTime.now.strftime("%d/%m/%Y %H:%M"),
        "store_path" => File.expand_path("~/.notecli"),
				"groups_path" => File.expand_path("~/.notecli/groups"),
				"pages_path" => File.expand_path("~/.notecli/pages"),
				"temp_path" => File.expand_path("~/.notecli/temp"),
				"editor" => "vi",
				"ext" => "txt"
      }
    end

    # loads configuration file which should be in the local profile or
    # etc. Examples include /etc/noterc and ~/.noterc
    def load
      @files.each do |c|
        config = File.expand_path(c)
        if File.exists? config
          @settings.deep_merge!(YAML.load_file(config))
        end
      end
      @settings
    end
	end
end
