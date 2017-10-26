
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

		class << self
			def default
				{
					"last_updated" => DateTime.now.strftime("%d/%m/%Y %H:%M"),
					"store_path" => File.expand_path("~/.notecli"),
					"group_path" => File.expand_path("~/.notecli/groups"),
					"page_path" => File.expand_path("~/.notecli/pages"),
					"temp_path" => File.expand_path("~/.notecli/temp"),
					"namespace" => "",	# for identifying current namespace path
					"history_path" => File.expand_path("~/.notecli"),
					"editor" => "vi",
					"ext" => "txt",
					"history_size" => 100
				}
			end

			def create
				c = self.new
				c.assert
				c	
			end
		end

		def assert
			@settings.select{|k,_|k["_path"]}.each do |k,v|
				FileUtils.mkdir_p v
			end
		end

    def initialize
      user_home = File.expand_path("~")
      @settings = Config::default
      @path = "#{user_home}/.notecli/config.yml"
      self.load
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

		# for getting the absolute store path
		# typically it is more correct to use "namespace" or "namespace_path"
		def store_path(path="/")
			File.expand_path(File.join(self.settings["store_path"], path))
		end

		# ergonomically change the namespace
		def set_namespace(ns="")
			self.settings["namespace"] = ns
		end

		# for ergonomics
		def namespace
			self.settings["namespace"]
		end

		# for ergonomically recalling the current fullpath of the namespace
		def namespace_path(path="")
			File.expand_path(File.join(self.store_path, self.namespace, path))
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
