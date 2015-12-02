# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yum_s3_sync/version'

Gem::Specification.new do |spec|
  spec.name          = 'yum_s3_sync'
  spec.version       = YumS3Sync::VERSION
  spec.authors       = ['Hein-Pieter van Braam']
  spec.email         = ['hp@tmm.cx']
  spec.summary       = 'Simple program to synchronize Yum repositories with S3 buckets'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency(%q<nokogiri>, [">= 1.4.3"])
  spec.add_runtime_dependency(%q<parallel>, [">= 1.6.1"])
  spec.add_runtime_dependency(%q<aws-sdk-v1>, [">= 0"])
end
