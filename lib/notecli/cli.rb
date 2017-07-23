
require 'thor'
require 'notecli/config'

module Notecli

  class Show < Thor
    desc "show groups (<groups> ...)", "shows all groupings or optionally specific groups"
    def groups(*args)
      say "Show groups #{args}"
    end
  end

  class CLI < Thor
    desc "open <filename>", "opens a file"
    def open(*args)
      say "open the following files in order: (#{args})"
    end 
    map "o" => :open

    desc "find <regex match>", "finds files with matching names"
    def find(*args)
      say "Find files matching this name: /#{args}/"
    end
    map "f" => :find

    desc "grep <regex match>", "finds files with matching data"
    def grep(*args)
      say "Grep for this string: /#{args}/"
    end
    map "g" => :grep

    desc "group <file1> ...", "groups target files together"
    def group(*args)
      say "Group these files: #{args}"
    end 

    desc "show <subcommand> ...<args>", "show details about note's internal management"
    subcommand :show, Show
    map "s" => :show
  end
end

