
require 'thor'
require 'notecli/config'
require 'notecli/group'
require 'notecli/page'
require "highline/import"

module Notecli

  ############################################################################## 
	# used to link pages and groups together
	class Link < Thor
		desc "groups MATCH [MATCH...] --to-page PAGE", "links groups to a page"
		option :"to-page", :type => :string
		def groups(*args)
			pageName = options[:"to-page"]
			if pageName
				puts "linking #{pageName} to:"
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

    ############################################################################ 
		desc "pages MATCH [MATCH...] --to-group GROUP", "links pages to a group"
		option :"to-group", :type => :string
		def pages(*args)
			groupName = options[:"to-group"]
			if groupName
				puts "linking #{groupName} to:"
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

  ##############################################################################
  class CLI < Thor
    config = Note::Config.new

		desc "groups REGEX", "lists all groups, or what groups match"
    option :'with-contents',
           :type => :boolean,
           :default => false,
           :aliases => [:'-w']
		def groups(match=".*")
			if match
				say "list all groupings with match \"#{match}\""
			else
				say "list all groupings"
			end

      if options[:'with-contents']
        puts Note::Group::list_contents(match).to_yaml
      else
        puts Note::Group::list(match).to_yaml
      end
		end

    ############################################################################   
    # opens one or more files inside notecli
    desc "open REGEX", "opens a file (matches regex)"
    option :'match', 
           :type => :boolean, 
           :default => false
    option :editor, 
           :type => :string, 
           :default => config.settings["editor"],
           :aliases => [:'-e']
    option :ext, 
           :type => :string, 
           :default => config.settings["ext"],
           :aliases => [:'-x']
    def open(*args)
      if options[:match]
        list = args.map{|f| Note::Page::find(f.name)}.flatten
      else
        list = args.map{|f| Note::Page.new(f)}.flatten
      end

      fileNames = list.map{|p| p.name}
      if list.length > 0
        say "open the following files in order: (#{fileNames})"
        Note::Page::open_multiple(
          list, 
          editor: options[:editor],
          ext: options[:ext])
      elsif list.length == 1
        say "open \"#{fileNames.first}\""
        list.first.open editor: options[:editor], ext: options[:ext]
      else
        say "no matches; could not open any files (#{fileNames})"
      end
    end
    map "o" => :open

    ############################################################################
    desc "find \"MATCH\"", "finds files with matching names"
    option :full_path, 
           :default => false,
           :type => :boolean,
           :aliases => [:'-p']
    def find(match="*")
      say "Find files matching this name: /#{match}/"
      if options[:full_path]
        puts Note::Page::find_path(match).map{|page| page.path}
      else
        puts Note::Page::find(match).map{|page| page.name}
      end
    end
    map "f" => :find

    ############################################################################
    desc "search REGEX", "finds files with matching data"
    def search(match)
      say "Match for this string: /#{match}/"
      res = Note::Page::search(match)

      res.each do |r|
        puts "#{r[:page].name}:#{r[:line]} -> #{r[:grep]}"
      end
    end
    map "s" => :search

    ############################################################################
    desc "config [KEY=VALUE ...]", 
         "set config keys on the command line (nesting works)"
    def config(key=nil, value=nil)
      conf = Note::Config.new
      if value
        say "setting #{key} to #{value}"
        conf.set(key, value)
      elsif key
        puts "#{conf.settings[key]}"
      else
        puts conf.settings.to_yaml
      end
    end
    map "c" => :config

    ############################################################################
    
    desc "rm MATCH",
         "removes a file with name match"
    option :force,
           :type => :boolean,
           :aliases => [:'-f']
    def rm(match)
      Note::Page::find(match).each do |page|
        if !options[:force]
          delete = ask "Delete #{page.name}? (y/n)"
          next if delete.downcase != "y"
        end
        page.delete
      end
      
    end

    ############################################################################
    desc "rmg MATCH",
         "removes a group with name match"
    option :'force',
           :type => :boolean,
           :aliases => [:'-f']
    def rmg(match)
      Note::Group::find(match).each do |group|
        if !options[:force]
          delete = ask "Delete #{group.name}? (y/n)"
          next if delete.downcase != "y"
        end
        group.delete
      end
    end
    
    ############################################################################
		desc "link SUBCOMMAND [OPTIONS]", "used to link groups and pages"
		subcommand :link, Link
		map "l" => :link
  end
end

