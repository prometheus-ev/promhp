require 'jekyll/rendering'
require 'jekyll/pagination'
require 'jekyll/localization'

module Jekyll

  module Helpers

    def relativize(str, current_page_url)
      return str if str =~ /\A[a-z]+:\/\//
      '../' * (current_page_url.count('/') - 1) + str.sub(/\A\//, '')
    end

    def pandora_url(path, site = OpenStruct.new(site.config), page = self)
      [site.pandora_url, page.lang, *path].compact.join('/')
    end

  end

  class Page

    include Helpers

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, base, dir, name)
      _prometheus_original_initialize(site, base, dir, name)

      data['navigation'] = render_navigation_level(
        YAML.load(
          ERB.new(
            File.read(
              File.join(@site.source, '_navigation.yml')
            )
          ).result(binding)
        )
      )
    end

    alias_method :_prometheus_original_process, :process

    # Overwrites the original method to fix handling of dotfiles.
    def process(name)
      _prometheus_original_process(name)
      self.basename = name if basename.empty?
    end

    private

    def render_navigation_level(level)
      "<ul>\n#{level.inject('') { |out, i| out << render_navigation_item(i) if i }}</ul>\n"
    end

    def render_navigation_item(item)
      path = File.join(@dir, basename)

      name = item["title_#{lang}".to_sym]
      name = "<a href=\"#{relativize(item[:url], path)}\">#{name}</a>" if item[:url]

      active = active?(item, path[1..-1])
      content = "\n#{render_navigation_level(item[:content])}\n" if item[:content] && active

      "<li#{' class="active"' if active}>#{name}#{content}</li>\n"
    end

    def active?(item, path)
      item[:url] == path || item[:content] && item[:content].any? { |i| active?(i, path) }
    end

  end

  class Post

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
      relativize(str, page.url)
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

end
