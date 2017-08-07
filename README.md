[![Build Status](https://travis-ci.org/zpallin/notecli.svg?branch=master)](https://travis-ci.org/zpallin/notecli) [![Coverage Status](https://coveralls.io/repos/github/zpallin/notecli/badge.svg?branch=master)](https://coveralls.io/github/zpallin/notecli?branch=master) 

# Notecli

Notecli is a command line application that allows you to write, organize, and manage your notes while you develop on the command line.

## Why you might use Notecli instead of a typical gui notetaking app

- You are already taking notes on the command line rather than in a typical gui app
- You are proficient in bash shell and enjoy using it
- You work exclusively in a terminal and cannot use a gui tool
- You would rather search for file content with a regular expression
- You want to write your notes in a plaintext format like `markdown`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'notecli'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install notecli

## Usage

```bash
$ cd $path_to_notecli
$ bundle --version
Bundler version 1.15.3
$ bundle exec rake install
$ note
Commands:
  note config [KEY=VALUE ...]     # set config keys on the command line (nesting works)
  note find "MATCH"               # finds files with matching names
  note groups REGEX               # lists all groups, or what groups match
  note help [COMMAND]             # Describe available commands or one specific command
  note link SUBCOMMAND [OPTIONS]  # used to link groups and pages
  note open REGEX                 # opens a file (matches regex)
  note search REGEX               # finds files with matching data
```

When installed, note runs with the command `note`. It uses [thor](http://whatisthor.com/) for CLI, which should give you some indiciation how it runs.

At this point, all of the commands "work" but ongoing changes to functionality will occur and this is not stable, hence version `0.0.1`.

### basic functions

To add a new note, simply run:

```bash
$ note open filename1
```

Note will open a file and save it in its pages directory located at `~/.notecli/pages`. Because of the way notecli works, you do not have to open the file from this directory, the command works fine.

If you forget the name of your file, you can run a string match to find it.

```bash
$ note find "f*"
Find files matching this name: /f*/
filename3
filename1
filename2
```

Then again, you can just open files with a string match too. In fact, it will open all of the matching files in order using your favorite command line text editor:

```bash
$ note open "f*" --match
open the following files in order: (["filename3", "filename1", "filename2"])
```

### Removing Pages

If you want to remove a page, you can just run a regex match to delete anything matching that string:

```bash
$ ./bin/note find f*
Find files matching this name: /f*/
filename
filename1
filename2
$ ./bin/note rm f*
Delete filename? (y/n) y
Delete filename1? (y/n) y
Delete filename2? (y/n) y
$ ./bin/note find f*
Find files matching this name: /f*/
```

### file format
You can easily use syntax formatting by forcing an extension on your file when you open it. 

```bash
$ note open filename1 --ext markdown
$ note open datafile1 --ext json
```

### more

There is a lot more functionality packed in here, so feel free to explore the options.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/notecli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Notecli project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/notecli/blob/master/CODE_OF_CONDUCT.md).
