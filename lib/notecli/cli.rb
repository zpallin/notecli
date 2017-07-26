
require 'thor'
require 'notecli/config'
require "highline/import"

module Notecli
  class Group < Thor
    desc "new NAME", "creates a new group with name"
    def new(name)
      say "Adding group \"#{name}\""
    end

    desc "files [FILE ...]", "adds file list to group"
    def files(*args)
      group = ask "Group name: "
      say "Add these files: (#{args}) to group \"#{group}\""
    end

    desc "describe REGEX", "describes group with name"
    def describe(name)
      say "Describe group with name \"#{name}\""
    end

    desc "list", "lists all groups"
    def list
      say "List all groups!"
    end
  end

  class CLI < Thor
    desc "open REGEX", "opens a file (matches regex)"
    def open(*args)
      say "open the following files in order: (#{args})"
    end 
    map "o" => :open

    desc "find REGEX", "finds files with matching names"
    def find(*args)
      say "Find files matching this name: /#{args}/"
    end
    map "f" => :find

    desc "match REGEX", "finds files with matching data"
    def match(*args)
      say "Match for this string: /#{args}/"
    end
    map "m" => :match

    desc "config [KEY=VALUE ...]", "set config keys on the command line (nesting works)"
    def config(*args)
      say "set the following configs: #{args}"
    end
    map "c" => :config

    desc "group SUBCOMMAND ...ARGS", "groups target files together"
    subcommand :group, Group
    map "g" => :group
  end
end

