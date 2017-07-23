
require 'notecli/version'
require 'notecli/cli'
require 'notecli/config'

################################################################################
# NoteConfig: a class for containing and managing the configuration 
# logic of note
#
#module Note
#  class Config
#    def initialize
#      @config = self.default_config
#      @config_files = ['~/.notecli.yml']
#      self.load
#      self.process
#    end
#
#    def default_config
#      {
#        "last_updated" => DateTime.now.strftime("%d/%m/%Y %H:%M")
#      }
#    end
#
#    # loads configuration file which should be in the local profile or
#    # etc. Examples include /etc/noterc and ~/.noterc
#    def load
#      @config_files.each do |c|
#        @config.deep_merge!(YAML.load_file(File.expand_path(c)))
#      end
#      @config
#    end
#
#    # after loading the config, we can run this to make any changes to 
#    # our environment via the config
#    def process
#      p @config
#    end
#  end
#end
#
