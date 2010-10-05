require 'jekyll/rendering'
require 'jekyll/pagination'
require 'jekyll/localization'

module Jekyll

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

  module Helpers

    def relativize(str, current_page_url)
      '../' * (current_page_url.count('/') - 1) + str.sub(/\A\//, '')
    end

  end

  module Filters

    include Helpers

    def r(str)
      relativize(str, @page.url)
    end

    def pandora(*path)
      [site.pandora_url, page.lang, *path].compact.join('/')
    end

    alias_method :p, :pandora

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

  end

  class Page

    include Helpers

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, base, dir, name)
      _prometheus_original_initialize(site, base, dir, name)

      generate_navigation
    end

    def generate_navigation
      unless self.data['navigation']
        self.data['navigation'] = ''
        structure = YAML.load_file(File.join(@site.source, '_navigation.yml'))
        self.data['navigation'] << render_navigation_level(structure)
      end
      return self.data['navigation']
    end

    def render_navigation_item(item)
      state = active_itme?(item) ? ' active' : ''
      if item[:url]
        name = "<a href=\"#{relativize(item[:url], path)}\">" +
          "#{item["title_#{lang}".to_sym]}</a>"
      else
        name = item["title_#{lang}".to_sym]
      end

      if item[:content].nil? || !opend?(item)
        "<li class=\"navigation_item#{state}\">#{name}</li>\n"
      else
        "<li class=\"navigation_item#{state}\">#{name}\n" +
          render_navigation_level(item[:content]) + "\n</li>\n"
      end
    end

    def render_navigation_level(level)
      out = "<ul>\n"
      level.each do |i|
        out << render_navigation_item(i) if i
      end
      out << "</ul>\n"
    end

    def path
      @path ||= File.join(@dir, basename)
    end

    def active_itme?(navigation_item)
      navigation_item[:url] == path[1..-1]
    end

    def opend?(navigation_item)
      return true if active_itme?(navigation_item)
      if navigation_item[:content]
        navigation_item[:content].each { |i| return true if opend?(i) }
      end

      return false
    end

  end

end
