require 'pp'
require 'fileutils'
require 'notecli/page'

module Note
  ###############################################################################
  # history stores the opened files history and can be used to referenced
  # recently opened files

  class History < FileOp
    def initialize
      Config.create
      compose 'history'
      touch
    end

    def add(pageinput, config: Config.new)
      if pageinput.class == Page
        page = pageinput
      elsif pageinput.class == String
        page = Page.new pageinput
      else
        return false
      end

      list = self.list
      list << page.name
      removeCount = list.length - config.settings['history_size']

      list = list.drop(removeCount) if removeCount > 0

      file = File.open(path, 'w')
      file.write(list.join("\n"))
      file.close
    end

    def list
      read.split("\n")
    end

    def self.home(config: Config.new)
      File.expand_path config.settings['store_path']
    end
  end
end
