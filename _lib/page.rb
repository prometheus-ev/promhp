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
      Pager.paginate_files(site.config).include?(File.join(@dir, name)[1..-1])
    end

    alias_method :_prometheus_original_dir=, :dir=

    def _prometheus_paginate_dir=(dir)
      base, name = File.split(dir)
      @dir = File.join(File.dirname(base), name)
    end

    def source
      File.join(@base, @dir, @name)
    end

    def full_url
      to_hash['url']
    end

  end

end
