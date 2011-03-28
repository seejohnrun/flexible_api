require File.dirname(__FILE__) + '/lib/flexible_api/version'

spec = Gem::Specification.new do |s|
  
  s.name = 'flexible_api'
  s.author = 'John Crepezzi'
  s.add_development_dependency('rspec')
  s.add_development_dependency('sqlite3')
  s.add_dependency('activerecord')
  s.description = 'API for making APIs'
  s.homepage = 'http://github.com/seejohnrun/flexible_api'
  s.summary = 'A flexible API for making APIs'
  s.email = 'john.crepezzi@gmail.com'
  s.files = Dir['lib/**/*.rb']
  s.has_rdoc = true
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.test_files = Dir.glob('spec/*.rb')
  s.version = FlexibleApi::VERSION
  s.rubyforge_project = 'flexible_api'

end
