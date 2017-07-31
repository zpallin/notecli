
require 'thor'
require 'notecli/config'
require "highline/import"

module Notecli

	# used to link pages and groups together
	class Link < Thor

		desc "groups MATCH [MATCH...] --to-page PAGE", "links groups to a page"
		option :"to-page", :type => :string
		def groups(*args)
			page = options[:"to-page"]
			if page
				puts "linking #{page} to #{args}"
				page = Note::Page.new page
				args.each do |name|
					group = Note::Group.new name
					group.add page
				end
			else
				say "Must use flag \"--to-page\""
			end
		end

		desc "pages MATCH [MATCH...] --to-group GROUP", "links pages to a group"
		option :"to-group", :type => :string
		def pages(*args)
			group = options[:"to-group"]
			if group
				puts "linking #{group} to #{args}"
				
			else
				say "Must use flag \"--to-group\""
			end
		end
	end

  class CLI < Thor
		desc "groups REGEX", "lists all groups, or what groups match"
		def groups(match=nil)
			if match
				say "list all groupings with match \"#{match}\""
			else
				say "list all groupings"
			end
		end

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

		desc "link SUBCOMMAND [OPTIONS]", "used to link groups and pages"
		subcommand :link, Link
		map "l" => :link
  end
end

