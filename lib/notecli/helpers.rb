
require 'notecli/page'
require 'notecli/group'
require 'notecli/config'

module Helpers
  include Note
  # process_pages
  #   compiles the list of requested pages and returns them -- standardized
  #   for multiple types of requests.
  #   - match => boolean # whether or not we will try to find matching pages
  #   - args => [] # pass the args from the cli input
  def process_pages(args, match: false)
    if match
      return args.map{|f|
        Page::find(f)
      }.flatten.map{|f|
        f.name
      }.uniq.map{|f|
        Page.new f
      }
    else
      return args.map{|f| Page.new(f)}.flatten
    end
  end

  # page_op
  #   all file operations will have the same behavior:
  #
  #   - `one` for single pages
  #   - `many` for multiple pages
  #   - `none` for no pages supplied
  #
  #   from this interaction you will inject the logic as lambdas
  #   this will be exposed as a block, similar to chef providers
  #   which will help with cleanliness.
  def page_op(name)
    @name = name
    @match = false
    @verbose = false
    @pages = []
    @one, @many, @none = [nil] * 3

    def match(m=true)
      @match = m
    end

    def verbose(v=false)
      @verbose = v
    end

    def pages(pgs=[])
      @pages = pgs
    end

    def action(func)
      instance_variable_set :"@#{__callee__}", func
    end

    alias one action
    alias many action
    alias none action
    
    yield if block_given?

    @pages = process_pages @pages, match: @match
    @pnames = @pages.map{|p| p.name}

    if @one and @pages.length == 1

      puts "#{@name}: \"#{@pnames.first}\"" if @verbose
      @one.call @pages if @one.respond_to? :call

    elsif @many and @pages.length > 1 and @many

      puts "#{@name} in order: (#{@pnames})" if @verbose
      @many.call @pages if @many.respond_to? :call

    elsif @none

      puts "no matches (#{@pnames})" if @verbose
      @none.call @pages if @none.respond_to? :call

    end
    pages
  end

end
