require 'fileutils'
require 'deep_merge'
require 'yaml'

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
      create name
    end

    def self.path_to(groupname = '', config: Config.new)
      File.expand_path File.join(config.settings['group_path'], groupname)
    end

    def self.assert
      FileUtils.mkdir_p Group.path_to
    end

    def self.list(match = '.*', config: Config.new)
      Group.assert

      all_groups = Dir.entries(Group.path_to).reject { |g| g =~ /^\.\.?$/ }
      all_groups.select { |g| g =~ /#{match}/ }
    end

    def self.list_contents(match = '.*', config: Config.new)
      contents = {}
      Group.list(match).each do |groupName|
        pages = Dir.entries(Group.path_to(groupName)).reject { |g| g =~ /^\.\.?$/ }
        contents[groupName] = pages
      end
      contents
    end

    # returns the dir -- automatically creates it if not done
    def create(name)
      Group.assert
      @name = name
      @path = Group.path_to name
      FileUtils.mkdir_p @path
    end

    def add(pages)
      [pages].flatten.each do |page|
        return false unless page.symlink File.join(@path, page.name)
      end
      true
    end

    def members
      entries = Dir.entries(@path).select { |f| File.file?(Page.new(f).path) }
      entries.map { |name| Page.new name }
    end

    def rename(name)
      FileUtils.mv @path, Group.path_to(name)
      create name
      true
    end
  end
end
