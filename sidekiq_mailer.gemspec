# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq_mailer/version'

Gem::Specification.new do |s|
  s.name          = "sidekiq_mailer"
  s.version       = SidekiqMailer::VERSION
  s.authors       = ["David Larrabee"]
  s.email         = ["david.larrabee@meyouhealth.com"]
  s.description   = %q{Common interface for mailings using sidekiq}
  s.summary       = %q{Thanks to resque_mailer}
  s.homepage      = ""
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency("actionmailer", ">= 3.0")

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rb-inotify'
  s.add_development_dependency 'rb-fsevent'
  s.add_development_dependency 'rb-fchange'
  s.add_development_dependency 'libnotify'
  s.add_development_dependency 'growl'
end
