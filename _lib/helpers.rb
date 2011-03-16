module Jekyll

  module Helpers

    def external_url?(str)
      str =~ %r{\A[a-z]+://}
    end

    def relative_url(str, current_page_url, absolute = false)
      if external_url?(str)
        str
      elsif absolute
        uri = site.respond_to?(:uri) ? site.uri : site.config['uri']
        File.join(uri.path, str)
      else
        count = current_page_url.count('/').pred
        count.zero? ? str.sub(/\A\//, '') : File.join(%w[..] * count, str)
      end
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
      url =~ %r{\A/?(?:#{Regexp.union(/page\d+/, d[0], d[1][%r{\A/:?(\w+)}, 1])})(?:/|\z)}
    end

  end

end
