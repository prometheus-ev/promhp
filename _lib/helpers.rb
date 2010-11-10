module Jekyll

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

end
