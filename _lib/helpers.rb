module Jekyll

  module Helpers

    def self.cache(*keys)
      (@__cache__ ||= {})[keys] ||= yield
    end

    def external_url?(str)
      str =~ %r{\A[a-z]+://}
    end

    def relative_url(str, url)
      external_url?(str) ? str : url.is_a?(URI) ?
        File.join(url.path, str) : _relative_url(str, url)
    end

    def _relative_url(str, url)
      count = url.count('/').pred
      count.zero? ? str.sub(/\A\//, '') : File.join(%w[..] * count, str)
    end

    def pandora_url(path, page = self, site = OpenStruct.new(site.config))
      [site.pandora_url, page.lang, *path].compact.join('/')
    end

    def blog?(url)
      url =~ Helpers.cache(:blog_re) {
        tag_page_dir, permalink = if site.respond_to?(:config)
          site.config.values_at(*%w[tag_page_dir permalink])
        else
          [site.tag_page_dir, site.permalink]
        end

        %r{\A/?(?:#{Regexp.union(
          /page\d+/, tag_page_dir,
          permalink[%r{\A/:?(\w+)}, 1]
        )})(?:/|\z)}
      }
    end

  end

end
