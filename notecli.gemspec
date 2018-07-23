lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'notecli/version'

Gem::Specification.new do |spec|
  spec.name          = 'notecli'
  spec.version       = Notecli::VERSION
  spec.authors       = ['zpallin']
  spec.email         = ['zpallin@gmail.com']

  spec.summary       = 'Note taking for bash users!'
  spec.description   = 'Note taking on the cli, helps keep notes organized!'
  spec.homepage      = 'https://github.com/zpallin/notecli.'
  spec.license       = 'MIT'

  ##############################################################################
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this section
  # to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  ##############################################################################
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'fakefs', '~> 0.11'
  spec.add_development_dependency 'mocha', '~> 1.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.6'
  spec.add_development_dependency 'simplecov', '~> 0.14'

  ##############################################################################
  spec.add_runtime_dependency 'deep_merge', '~> 1.1'
  spec.add_runtime_dependency 'highline', '~> 1.7'
  spec.add_runtime_dependency 'thor', '~> 0.19'
end
