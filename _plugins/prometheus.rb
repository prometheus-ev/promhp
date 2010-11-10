require 'jekyll/rendering'
require 'jekyll/pagination'
require 'jekyll/localization'
require 'jekyll/tagging'

class OpenStruct
  alias_method :[], :send
end

module Jekyll

  Localization::LANGUAGES.replace(%w[en de])

  module Helpers

    def relative_url(str, current_page_url)
      return str if str =~ /\A[a-z]+:\/\//
      '../' * (current_page_url.count('/') - 1) + str.sub(/\A\//, '')
    end

    def pandora_url(path, site = OpenStruct.new(site.config), page = self)
      [site.pandora_url, page.lang, *path].compact.join('/')
    end

    def blog?(url)
      d = if site.respond_to?(:config)
        site.config.values_at(*%w[tag_page_dir permalink])
      else
        [site.tag_page_dir, site.permalink]
      end

      url =~ %r{\A/?(?:#{Regexp.union(d[0], d[1][%r{\A/:?(\w+)}, 1])})(?:/|\z)}
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
        (blog?(path) && blog?(item[:url])) ||
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

    alias_method :_prometheus_original_index?, :index?

    def index? # TODO: Puzzle the whole "pagination index in a subdir" stuff in jekyll-pagination gem.
      file = File.join(@dir, name)[1..-1]
      Pager.paginate_files(@site.config).include?(file)
    end

    alias_method :_prometheus_original_dir=, :dir=

    def _prometheus_paginate_dir=(dir)
      base, name = File.split(dir)
      @dir = File.join(File.dirname(base), name)
    end

  end

  class Post

    include Helpers
    include Navigation

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, source, dir, name)
      _prometheus_original_initialize(site, source, dir, name)

      @dir = self.dir
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

  class Pager

    def link_at(pos)
      pos == 1 ? 'blog' : "page#{pos}"  # TODO: Make these dynamic.
    end

    def first_link
      link_at(1) if page > 1
    end

    def last_link
      link_at(total_pages) if page < total_pages
    end

    def previous_link
      link_at(previous_page) if previous_page
    end

    def next_link
      link_at(next_page) if next_page
    end

    alias_method :_prometheus_original_to_liquid, :to_liquid

    def to_liquid
      _prometheus_original_to_liquid.merge(
        :first_link    => first_link,
        :last_link     => last_link,
        :previous_link => previous_link,
        :next_link     => next_link
      )
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

    def paginator_first_link
      if href = @paginator.first_link
        %Q{<a href="#{r(href)}"><div class="icon_first"></div></a>}
      else
        '<div class="icon_first inactive"></div>'
      end
    end

    def paginator_last_link
      if href = @paginator.last_link
        %Q{<a href="#{r(href)}"><div class="icon_last"></div></a>}
      else
        '<div class="icon_last inactive"></div>'
      end
    end

    def paginator_previous_link
      if href = @paginator.previous_link
        %Q{<a href="#{r(href)}"><div class="icon_prev"></div></a>}
      else
        '<div class="icon_prev inactive"></div>'
      end
    end

    def paginator_next_link
      if href = @paginator.next_link
        %Q{<a href="#{r(href)}"><div class="icon_next"></div></a>}
      else
        '<div class="icon_next inactive"></div>'
      end
    end

    def paginator_navigation
      [
        paginator_first_link, paginator_previous_link,
        t('Page', 'Seite'),  @paginator.page,  # TODO: Make this dynamic?
        t('of',   'von'),    @paginator.total_pages,
        paginator_next_link,  paginator_last_link
      ].join(' ')
    end

    def tag_url(tag, dir = site.tag_page_dir)
      r(File.join(dir, u(tag)))
    end

    alias_method :_prometheus_original_tags, :tags

    def tags(obj)
      obj = { 'tags' => obj.tags } if obj.is_a?(Jekyll::Post)
      _prometheus_original_tags(obj)
    end

  end

  class Pagination

    alias_method :_prometheus_original_generate, :generate

    def generate(site)
      site.pages.dup.each do |page|
        file = File.join(page.instance_variable_get(:@dir), page.name)[1..-1]
        paginate(site, page) if Pager.pagination_enabled?(site.config, file)
      end
    end

    alias_method :_prometheus_original_paginate, :paginate

    def paginate(site, page)
      def page.dir; @dir; end
      Page.send(:alias_method, :dir=, :_prometheus_paginate_dir=)

      _prometheus_original_paginate(site, page)
    ensure
      class << page; remove_method :dir; end
      Page.send(:alias_method, :dir=, :_prometheus_original_dir=)
    end

  end

  class Tagger

    alias_method :_prometheus_original_generate_tag_pages, :generate_tag_pages

    def generate_tag_pages(site)
      tags, original_tags = [], site.tags.dup

      Localization::LANGUAGES.each { |lang|
        original_tags.each { |tag, posts| tags << ["#{tag}.#{lang}", posts] }
      }

      site.tags = tags
      _prometheus_original_generate_tag_pages(site)
    ensure
      site.tags = original_tags if original_tags
    end

  end

end
