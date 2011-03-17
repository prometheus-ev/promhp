module Jekyll

  module Helpers

    def external_url?(str)
      str =~ %r{\A[a-z]+://}
    end

    def relative_url(str, url)
      if external_url?(str)
        str
      elsif url.is_a?(URI)
        File.join(url.path, str)
      else
        count = url.count('/').pred
        count.zero? ? str.sub(/\A\//, '') : File.join(%w[..] * count, str)
      end
    end

    def pandora_url(path, page = self, site = OpenStruct.new(site.config))
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
