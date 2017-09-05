
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
    def open(editor: nil, ext: nil)

      editor ||= @settings["editor"]
      ext ||= @settings["ext"]

      self.class.assert_home
      temp = self.temp ext
      
      system(editor.to_s, temp.to_s)

      history = History.new
      history.add self.name

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

      self::assert_home
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

    # creates a symlink in a temp directory
    def temp(ext=nil, temp_path=nil)

      temp_path ||= @settings["temp_path"]
      ext ||= @settings["ext"]
     
      to_path = File.join(
        temp_path, 
        [@name, ext].join(".")
      )
      FileUtils.mkdir_p temp_path
      self.symlink to_path
      to_path
    end

    # removes a temp file after it is created
    def rm_temp(file_ext, temp_path: @settings["temp_path"])
      path = File.join(temp_path, [@name, file_ext].join("."))
      if File.file? path
        FileUtils.rm path
      end
    end
  end
end
