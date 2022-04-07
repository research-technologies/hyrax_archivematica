lib = File.expand_path('../lib', __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hyrax_archivematica/version'

Gem::Specification.new do |s|
  s.name          = 'hyrax_archivematica'
  s.version       = HyraxArchivematica::VERSION
  s.summary       = "Integration for Hyrax/Archivematica"
  s.description   = "A gem that will build bags and send them to archviematica for preservartion and record the AM UUID"
  s.authors       = ["Rory McNicholl"]
  s.email         = 'rory.mcncholl@london.ac.uk'
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
#  s.homepage     =
#    'https://rubygems.org/gems/hyrax-archivematica'
  s.licenses = ["Apache-2.0".freeze]


end

