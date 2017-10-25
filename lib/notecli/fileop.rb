
################################################################################
module Note
  # FileOp class provides common functionality for all of the objects that touch 
  # files
  class FileOp
    attr_reader :name, :path, :book
    
    ############################################################################
    # static functionality
    class << self

      # check if a file exists for this class
      def exists?(path)
				f = FileOp.new(path)
        File.exists? f.path
      end
      alias_method :exist?, :exists?

			# used so that "new" doesn't automatically touch a file
			def create(path)
				f = self.new path
				f.touch
				f
			end
    end

    ############################################################################ 
    # methods

    # by default, it saves the config 
    def initialize(path)
			Config.create
      self.compose path
    end

    # creates a symlink to another path for the original path of
    # this page
    def symlink(to_path)
      FileUtils.rm to_path if File.exist? to_path
      FileUtils.ln_s(@path, to_path)
    end

    # runs all of the creation steps for the page dir
    def compose(local_path=nil, config: Config.new)
			@local_path = local_path if local_path
			@path = File.join(config.namespace_path, local_path)
			parsed = @local_path.rpartition('/')
      @name = parsed.last
			@book = Book.new (parsed.length > 1 ? parsed.first : "")
    end

    def touch
      FileUtils.touch(@path)
    end

    # renames a file to a new name and checks if a file
    # exists first
    def rename(name)
			newpath = @book.path_to(name)
      FileUtils.mv @path, newpath
      self.compose newpath
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
