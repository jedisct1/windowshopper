# -*- encoding: utf-8 -*-

$: << File.expand_path("../lib", __FILE__)

require "windowshopper/version"

Gem::Specification.new do |s|
  s.name = "windowshopper"
  s.version = WindowShopper::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Frank Denis"]
  s.summary = "Predicts a shopper's behavior"
  s.description = s.summary
  s.required_ruby_version = ">=1.9.2"
  s.add_development_dependency "awesome_print"

  ignores = File.readlines(".gitignore").grep(/\S+/).map {|i| i.chomp }.
    map {|i| File.directory?(i) ? i.sub(/\/?$/, '/*') : i }

  dotfiles = [".gitignore"]

  s.files = Dir["**/*"].reject {|f| File.directory?(f) ||
    ignores.any? {|i| File.fnmatch(i, f) } } + dotfiles

  s.require_paths = ['lib']
end
