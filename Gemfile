source 'https://rubygems.org'

require 'json'
require 'open-uri'
versions = JSON.parse(URI('https://pages.github.com/versions.json').open.read)

gem 'github-pages', versions['github-pages']
gem 'gsl'
gem 'wdm', '~> 0.1.0' if Gem.win_platform?
