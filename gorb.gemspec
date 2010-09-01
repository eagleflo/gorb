Gem::Specification.new do |gem|
  gem.name    = 'gorb'
  gem.version = '0.0.1'

  gem.summary = "Ruby go library"
  gem.description = "gorb is a go (board game) library written in pure Ruby."

  gem.authors  = ['Aku Kotkavuo']
  gem.email    = 'aku@hibana.net'
  gem.homepage = 'http://github.com/arkx/gorb'

  gem.files = Dir['Rakefile', '{lib, test}/**/*', 'README', 'LICENSE']
end
