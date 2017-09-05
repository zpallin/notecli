
require "fileutils"
require "deep_merge"
require "yaml"

module Note
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
      @path = "#{user_home}/.notecli/config.yml"
      self.load
    end

    def self.default
      {
        "last_updated" => DateTime.now.strftime("%d/%m/%Y %H:%M"),
        "store_path" => File.expand_path("~/.notecli"),
				"group_path" => File.expand_path("~/.notecli/groups"),
				"page_path" => File.expand_path("~/.notecli/pages"),
				"temp_path" => File.expand_path("~/.notecli/temp"),
        "history_path" => File.expand_path("~/.notecli"),
				"editor" => "vi",
				"ext" => "txt",
        "history_size" => 100
      }
    end

    def last_updated
      self.set("last_updated", DateTime.now.strftime("%Y-%m-%d %H:%M"))
    end

    def set(key, value)
      settings = self.load
      settings[key] = value
      config_path = File.expand_path(@path)
      open(config_path, "w") do |c|
        c.write settings.to_yaml
      end
      self.last_updated if key != "last_updated"
    end

    # loads configuration file which should be in the local profile or
    # etc. Examples include /etc/noterc and ~/.noterc
    def load
      config = File.expand_path(@path)
      if File.exists? config
        @settings.deep_merge!(YAML.load_file(config))
      end
      @settings
    end
	end
end
