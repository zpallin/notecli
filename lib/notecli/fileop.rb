
################################################################################
module Note
  # FileOp class provides common functionality for all of the objects that touch 
  # files
  class FileOp
    attr_reader :name, :path
    
    ############################################################################
    # static functionality
    class << self
      # returns the home directory of the class, can be overwritten for choosing
      # a custom class home, but the default is to use the class name
      def home(config: Config.new)
        name = self.name.split(':').last.downcase
        confPathName = "#{name}_path"
        storPath = config.settings["store_path"]
        setPath = config.settings[confPathName] || File.join(storPath)
        
        File.expand_path setPath
      end

      # returns the full path to the file by the name given, or the path to the
      # home directory determined by the name of the class
      def path_to(name="", config: Config.new)
        File.expand_path File.join(self::home, name)
      end

      # assert the existence of the home directory for this module
      def assert_home
        FileUtils.mkdir_p self::path_to
      end
      
      # check if a file exists for this class
      def exists?(name)
        File.exists? self::path_to(name)
      end
      alias_method :exist?, :exists?

      # finds a file in this object scope with the matching name
      def find(match="*")
        self::find_path(match).map{|f| self.new File.basename(f)}
      end

      # returns full paths for each matching file name
      def find_path(match="*")
        Dir[(self::path_to match)]
      end

      def search(match="*")
        found = []
        self::find.each do |f|
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

    ############################################################################ 
    # methods

    # by default, it saves the config 
    def initialize(name, config: Config.new)
      self.update_settings(config: config)
      self.class.assert_home
      self.create name
    end

    # update with notecli global settings
    def update_settings(config: Config.new)
      @settings = config.settings
    end

    # creates a symlink to another path for the original path of
    # this page
    def symlink(to_path)
      FileUtils.rm to_path if File.exist? to_path
      FileUtils.ln_s(@path, to_path)
    end

    # runs all of the creation steps for the page dir
    def create(name)
      @name = name
      @path = self.class.path_to name
      self.touch
    end

    def touch
      FileUtils.touch(@path)
    end

    # renames a file to a new name and checks if a file
    # exists first
    def rename(name)
      FileUtils.mv @path, self.class.path_to(name)
      self.create name
      return true
    end

    # delete the page
    def delete
      FileUtils.rm @path
    end

    # write file
    def write(data)
      data = data.join("\n") if data.kind_of?(Array)

      file = File.open(self.path, "w")
      file.write(data)
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
