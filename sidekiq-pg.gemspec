require_relative 'lib/sidekiq/pg/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-pg'
  spec.version       = Sidekiq::Pg::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']
  spec.summary       = 'PostgreSQL adapter for Sidekiq'
  spec.description   = 'Use PostgreSQL with unlogged tables as a Sidekiq store instead of Redis'
  spec.homepage      = 'https://github.com/yourusername/sidekiq-pg'
  spec.license       = 'MIT'

  spec.files = Dir.glob('lib/**/*') + ['README.md', 'LICENSE']
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq', '~> 7.0'
  spec.add_dependency 'pg', '~> 1.0'
  spec.add_dependency 'connection_pool', '~> 2.2'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-shopify', '~> 2.0'
end