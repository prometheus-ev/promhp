require 'jekyll/rendering'
require 'jekyll/pagination'
require 'jekyll/localization'

module Jekyll

  class Page

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, base, dir, name)
      _prometheus_original_initialize(site, base, dir, name)

      pandora_url  = @site.config['pandora_url']
      pandora_url += "/#{@lang}" if pandora_url && @lang
      @pandora_url = data['pandora_url'] = pandora_url
    end

  end

  class Post

    def title
      to_hash['title']
    end

    alias_method :_localization_original_url, :url

    # Overwrites the original method to include the language extension.
    def url
      _localization_original_url.sub(/\.\w{2}\z/, '')
    end

    alias_method :_prometheus_original_write, :write

    # Overwrites the original method to not put our output files as
    # 'index.html' in a directory called by their slug.
    def write(dest)
      FileUtils.mkdir_p(File.join(dest, dir))

      # The url needs to be unescaped in order to preserve the correct filename
      path = File.join(dest, CGI.unescape(self.url + '.html' + @lang_ext))

      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end

  end

  module Filters

    def relativize(str)
      '../' * (@page.url.count('/') - 1) + str.sub(/\A\//, '')
    end
    alias_method :r, :relativize

  end

  class Pagination < Generator

    alias_method :_prometheus_original_paginate, :paginate

    # Overwrites the original method to prevent double posts in pagination
    def paginate(site, page)
      all_posts = site.site_payload['site']['posts']
      all_posts = uniq_by_url(all_posts)
      pages = Pager.calculate_pages(all_posts, site.config['paginate'].to_i)
      (1..pages).each do |num_page|
        pager = Pager.new(site.config, num_page, all_posts, pages)
        if num_page > 1
          newpage = Page.new(site, site.source, page.dir, page.name)
          newpage.pager = pager
          newpage.dir = File.join(page.dir, "page#{num_page}")
          site.pages << newpage
        else
          page.pager = pager
        end
      end
    end

    def uniq_by_url(posts)
      uniq_posts = {}
      posts.each { |p| uniq_posts[p.url] = p }
      uniq_posts.values.sort_by { |p| p.date }.reverse
    end

  end

end
