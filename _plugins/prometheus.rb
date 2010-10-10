require 'jekyll/rendering'
require 'jekyll/pagination'
require 'jekyll/localization'

module Jekyll

  module Helpers

    def relative_url(str, current_page_url)
      return str if str =~ /\A[a-z]+:\/\//
      '../' * (current_page_url.count('/') - 1) + str.sub(/\A\//, '')
    end

    def pandora_url(path, site = OpenStruct.new(site.config), page = self)
      [site.pandora_url, page.lang, *path].compact.join('/')
    end

  end

  module Navigation

    def render_navigation_level(level)
      "<ul>\n#{level.inject('') { |out, i| out << render_navigation_item(i) if i }}</ul>\n"
    end

    def render_navigation_item(item)
      path = File.join(@dir, basename)

      name = item["title_#{lang}".to_sym]
      name = "<a href=\"#{relative_url(item[:url], path)}\">#{name}</a>" if item[:url]

      active = active?(item, path[1..-1])
      content = "\n#{render_navigation_level(item[:content])}\n" if item[:content] && active

      "<li#{' class="active"' if active}>#{name}#{content}</li>\n"
    end

    def active?(item, path)
      path =~ /\A#{Regexp.escape(item[:url])}/ ||
        (item[:content] || []).any? { |i| active?(i, path) }
    end

    def load_navigaion
      render_navigation_level(
        YAML.load(
          ERB.new(
            File.read(
              File.join(@site.source, '_navigation.yml')
            )
          ).result(binding)
        )
      )
    end

  end

  class Page

    include Helpers
    include Navigation

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, base, dir, name)
      _prometheus_original_initialize(site, base, dir, name)

      data['navigation'] = load_navigaion
    end

    alias_method :_prometheus_original_process, :process

    # Overwrites the original method to fix handling of dotfiles.
    def process(name)
      _prometheus_original_process(name)
      self.basename = name if basename.empty?
    end

    alias_method :_pagination_original_index?, :index?

    def index? # TODO: Puzzle the whole "pagination index in a subdir" stuff in jekyll-pagination gem.
      file = File.join(@dir, name)[1..-1]
      Pager.paginate_files(@site.config).include?(file)
    end

  end

  class Post

    include Helpers
    include Navigation

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, source, dir, name)
      _prometheus_original_initialize(site, source, dir, name)

      @dir = send(:dir)
      data['navigation'] = load_navigaion
    end

    def basename
      slug.sub(/\.[a-z]{2}\z/, '')
    end

    def title
      to_hash['title']
    end

    alias_method :_prometheus_original_url, :url

    # Overwrites the original method to drop the language extension.
    def url
      _prometheus_original_url.sub(/#{Localization::LANG_EXT_RE}\z/, '')
    end

    alias_method :_prometheus_original_write, :write

    # Overwrites the original method to not put our output files as
    # 'index.html' in a directory called by their slug.
    def write(dest)
      FileUtils.mkdir_p(File.join(dest, dir))

      # The url needs to be unescaped in order to preserve the correct filename
      path = File.join(dest, CGI.unescape("#{url}.html#{@lang_ext}"))

      File.open(path, 'w') { |f| f.write(output) }
    end

  end

  module Filters

    include Helpers

    def r(str)
      relative_url(str, page.url)
    end

    def p(*path)
      pandora_url(path, site, page)
    end

    def page_title(head = false)
      parts, title = page.url.sub(/\A\//, '').split('/'), page.title

      case parts.first
        when /\A\d+\z/
          pre = "#{t('prometheus Blog', 'prometheus-Blog')} - " if head
          "#{pre}#{title}"
        when 'series'
          num = parts.values_at(-2, -3).join(' / ')
          "#{t('Image series', 'Bildserie')} #{num}: #{title}"
        else
          title
      end
    end

    def paginator_previous_link(link_text = '&lt;&lt;')
      if @paginator.page == 2
        href = 'blog' # TODO: Make this dynamic.
      elsif @paginator.page > 2
        href = "page#{@paginator.previous_page}"
      end
      href ? "<a href=\"#{r(href)}\">#{link_text}</a>" : link_text
    end

    def paginator_next_link(link_text = '&gt;&gt;')
      if @paginator.page == @paginator.total_pages
        link_text
      else
        href = "page#{@paginator.next_page}"
        "<a href=\"#{r(href)}\">#{link_text}</a>"
      end
    end

    def paginator_navigation(previous_link = '&lt;&lt;', next_link = '&gt;&gt;')
      "#{paginator_previous_link(previous_link)} | #{@paginator.page} | #{paginator_next_link(next_link)}"
    end

  end

  class Pagination

    alias_method :_pagination_original_generate, :generate

    def generate(site)
      site.pages.dup.each do |page|
        file = File.join(page.instance_variable_get(:@dir), page.name)[1..-1]
        paginate(site, page) if Pager.pagination_enabled?(site.config, file)
      end
    end

    alias_method :_pagination_original_paginate, :paginate

    def paginate(site, page)

      def page.dir
        @dir
      end

      Page.send(:define_method, :dir=) { |dir|
        dir = dir.split('/')
        dir.delete_at(dir.size - 2)
        @dir = dir.join('/')
      }

      _pagination_original_paginate(site, page)

      class << page
        remove_method :dir
      end
    end

  end

end
