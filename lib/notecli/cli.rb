
require 'thor'
require 'notecli/config'
require "highline/import"

module Notecli

	# used to link pages and groups together
	class Link < Thor
		desc "groups MATCH [MATCH...] --to-page PAGE", "links groups to a page"
		option :"to-page", :type => :string
		def groups(*args)
			pageName = options[:"to-page"]
			if pageName
				puts "linking #{page} to:"
				page = Note::Page.new pageName
				args.each do |groupName|
          puts " - #{groupName}"
					group = Note::Group.new groupName
					group.add page
				end
			else
				say "Must use flag \"--to-page\""
			end
		end

		desc "pages MATCH [MATCH...] --to-group GROUP", "links pages to a group"
		option :"to-group", :type => :string
		def pages(*args)
			groupName = options[:"to-group"]
			if groupName
				puts "linking #{group} to:"
        group = Note::Group.new groupName
		    args.each do |pageName|
          puts " - #{pageName}"
          page = Note::Page.new pageName
          group.add page
        end    
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
      args.map{|f| Note::Page::find(f)}.flatten.uniq.each do |f|
        
      end
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
