module Jekyll

  class Page

    include Helpers
    include Navigation

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, base, dir, name)
      _prometheus_original_initialize(site, base, dir, name)
      load_navigation
    end

    alias_method :_prometheus_original_process, :process

    # Overwrites the original method to fix handling of dotfiles.
    def process(name)
      _prometheus_original_process(name)
      self.basename = name if basename.empty?
    end

    alias_method :_prometheus_original_index?, :index?

    def index? # TODO: Puzzle the whole "pagination index in a subdir" stuff in jekyll-pagination gem.
      file = File.join(@dir, name)[1..-1]
      Pager.paginate_files(site.config).include?(file)
    end

    alias_method :_prometheus_original_dir=, :dir=

    def _prometheus_paginate_dir=(dir)
      base, name = File.split(dir)
      @dir = File.join(File.dirname(base), name)
    end

  end

end
