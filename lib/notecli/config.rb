
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
    attr_reader :name

    def initialize(name, home)
      @name = name
      @home = File.expand_path(home)
      @path = File.join(@home, "groups", @name)
      self.create
    end

    # returns the created dir -- also automatically inserts groups
    def create
      FileUtils.mkdir_p @path
    end

    def add(pages)
      errors = []
      pages.each do |page|
        out = page.symlink(page.path)
        if out != 0
          errors << out
        end
      end
      return errors
    end

    def members
      puts "Listing members"
    end

    def rename
      puts "Rename this group"
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
  
    def initialize(path)
      @path = File.expand_path path
      @name = path.split("/").last
      self.create
    end

    def symlink(path)
      FileUtils.symlink path, @path
    end

    def create
      FileUtils.touch(@path)
    end

    def open

    end

    def rename

    end

    def delete

    end

    # echos the file contents to stdout so that you may redirect it to a new
    # file somewhere on your desktop rather than within note's file structure
    def read
      
    end

  end

  ############################################################################## 
  # config merges default configuration and local configuration on top.
  # You cannot change default config, and all config changes are stored in 
  # ~/.notecli.yml, for now, meaning that there are no global changes yet.
  # Only changes for local users.
  class Config
    def initialize
      user_home = File.expand_path("~")
      @config = self.default_config
      @config_files = ["#{user_home}/.notecli/config.yml"]
      self.load
      self.process
    end

    def default_config
      {
        "last_updated" => DateTime.now.strftime("%d/%m/%Y %H:%M"),
        "storage_path" => File.expand_path("~/.notecli"),
      }
    end

    # loads configuration file which should be in the local profile or
    # etc. Examples include /etc/noterc and ~/.noterc
    def load
      @config_files.each do |c|
        config = File.expand_path(c)
        if File.exists? config
          @config.deep_merge!(YAML.load_file(config))
        end
      end
      @config
    end

    # after loading the config, we can run this to make any changes to
    # our environment via the config
    def process
      #p @config
    end
  end


  ##############################################################################
  # manages an instance of note and combines config with objects 
  class Instance
    def initialize(config)

    end
  end
end
