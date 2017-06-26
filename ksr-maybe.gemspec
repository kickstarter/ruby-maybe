Gem::Specification.new do |s|
  s.name = 'ksr-maybe'
  s.version = '0.1.0'
  s.summary = 'A library providing the optional type \'Maybe\''
  s.authors = ['Ryan Closner', 'Corey Farwell']
  s.email = 'eng@kickstarter.com'
  s.files = `git ls-files`.split("\n")
  s.homepage = 'http://github.com/kickstarter/ruby-maybe'
  s.license = 'Apache-2.0'

  s.add_dependency 'contracts', '~> 0.16.0'

  s.add_development_dependency 'shoulda-context', '~> 1.2'
  s.add_development_dependency 'minitest', '~> 5.10'
  s.add_development_dependency 'rake', '~> 12.0'
end
