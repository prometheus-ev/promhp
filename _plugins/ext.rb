Dir["#{ENV['DEVEL']}/jekyll-*/lib"].each { |d| $:.unshift(d) } if ENV['DEVEL']

YAML::ENGINE.yamler = 'syck' if YAML.const_defined?(:ENGINE)

LIBDIR = File.expand_path('../../_lib', __FILE__)

%w[
  uri
].each { |lib|
  require lib
}

%w[
  rendering
  pagination
  localization
  tagging
].each { |plugin|
  require "jekyll/#{plugin}"
}

%w[
  core_ext localization
  helpers navigation rendering
  site page post pagination
  series tagger filters
  initializer authors
].each { |lib|
  require File.join(LIBDIR, lib)
}
