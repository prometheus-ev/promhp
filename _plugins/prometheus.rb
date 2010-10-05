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

  module Filters

    def relativize(str)
      '../' * (page.url.count('/') - 1) + str.sub(/\A\//, '')
    end

    alias_method :r, :relativize

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

end
