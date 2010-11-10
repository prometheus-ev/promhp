LIBDIR = File.expand_path('../../_lib', __FILE__)

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
  helpers navigation
  page post pagination
  series tagger filters
].each { |lib|
  require File.join(LIBDIR, lib)
}
