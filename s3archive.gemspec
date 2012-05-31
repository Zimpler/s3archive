# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "s3archive"
  s.version     = '1.3.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Petter Remen"]
  s.email       = ["petter@spnab.com"]
  s.homepage    = "http://github.com/spab/s3archive"
  s.summary     = "Simple script to safely archive a file to S3"
  s.description = ""

  s.add_runtime_dependency 'thor', '~> 0.14.6'
  s.add_runtime_dependency 'right_aws', '~> 3.0.0'
  s.add_development_dependency "rspec", '~> 2.9.0'

  s.files        = Dir.glob("{bin,lib}/**/*")
  s.executables  = ['s3archive']
  s.require_path = 'lib'
end
