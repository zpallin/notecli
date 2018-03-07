
require "fileutils"
require "deep_merge"
require "yaml"
require "notecli/history"

module Note
  ############################################################################## 
  # a page is a file, no less. This class contains to means to crud a file
  # more or less. Called a page to avoid name confict
  #
  # this class operates to interaction with the file structure, does not store
  # any state data.
  class Page < FileOp

    # opens a file with the editor and file type provided
    # a file is symlinked to a tmp directory and opened with 
    # a different file extension
    def open(editor: nil, ext: nil, config: Config.create)

      editor ||= config.settings["editor"]
      ext ||= config.settings["ext"]
      temp = self.temp ext
      
      system(editor.to_s, temp.to_s)

      history = History.new
      history.add self.path

      self.rm_temp ext
      self.cleanup!
    end

    def cleanup!
      data = self.read.split.join(" ")
      if data == ""
        self.delete
      end
    end

    def self.open_multiple(pages, editor: nil, ext: nil, config: Config.new)
      
      editor ||= config.settings["editor"]
      ext ||= config.settings["ext"]
      history = History.new

      temps = pages.map{|page| page.temp ext}
      if temps.length > 0
        conns = "#{editor} #{temps.join(' ')}"
        system(conns)
        pages.each do |page|
          history.add page.name
          page.rm_temp ext
          page.cleanup!
        end
      end  
      temps
    end

    # process_pages
    #   compiles the list of requested pages and returns them -- standardized
    #   for multiple types of requests.
    #
    #   - match => boolean # whether or not we will try to find matching pages
    #   - args => [] # pass the args from the cli input
    #
    def self.process_pages(args, match: false)
      if match
        return args.map{|f|
					page = Page.new f
          page.book.list_pages(f)
        }.flatten.map{|f|
          f.name
        }.uniq.map{|f|
          Page.create f
        }
      else
        return args.map{|f| Page.create(f)}.flatten
      end
    end

    ############################################################################ 
    # creates a symlink in a temp directory
    def temp(ext=nil, temp_path=nil, config: Config.new)

      temp_path ||= config.settings["temp_path"]
      ext ||= config.settings["ext"]
     
      to_path = File.join(
        temp_path, 
        [@name, ext].join(".")
      )
      FileUtils.mkdir_p temp_path
      self.symlink to_path
      to_path
    end

    # removes a temp file after it is created
    def rm_temp(file_ext, temp_path: Config.new.settings["temp_path"])
      path = File.join(temp_path, [@name, file_ext].join("."))
      if File.file? path
        FileUtils.rm path
      end
    end
  end


  # page_op
  # standardized logic or opening files under unique conditions to abstract
  # new logic for CLI. Helps CLI maintain simplicity:
  # 
  #   ```
  #   - `one` for single pages
  #   - `many` for multiple pages
  #   - `none` for no pages supplied
  #   ```
  #
  #   From this interaction you will inject the logic as lambdas
  #   this will be exposed as a block, similar to chef providers
  #   which will help with cleanliness.
  #
  def page_op(name)
    @name = name
    @match = false
    @verbose = false
    @pages = []
    @one, @many, @none = [nil] * 3
    
    def match(m=true)
      @match = m
    end

    def verbose(v=false)
      @verbose = v
    end

    def pages(pgs=[])
      @pages = pgs
    end

    def action(func)
      instance_variable_set :"@#{__callee__}", func
    end

    alias one action
    alias many action
    alias none action

    yield if block_given?

    @pages = Page::process_pages @pages, match: @match
    @pnames = @pages.map{|p| p.name}

    if @one and @pages.length == 1

      puts "#{@name}: \"#{@pnames.first}\"" if @verbose
      @one.call @pages if @one.respond_to? :call

    elsif @many and @pages.length > 1 and @many

      puts "#{@name} in order: (#{@pnames})" if @verbose
      @many.call @pages if @many.respond_to? :call

    elsif @none

      puts "no matches (#{@pnames})" if @verbose
      @none.call @pages if @none.respond_to? :call

    end
    @pages
  end
end
