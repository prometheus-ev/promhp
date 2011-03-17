module Jekyll

  class Post

    include Helpers
    include Navigation

    alias_method :_prometheus_original_initialize, :initialize

    def initialize(site, source, dir, name)
      _prometheus_original_initialize(site, source, dir, name)

      self.tags.flatten!
      @dir = self.dir
      load_navigation
    end

    def basename
      slug.sub(Localization::LANG_END_RE, '')
    end

    def title
      to_hash['title']
    end

    alias_method :_prometheus_original_url, :url

    # Overwrites the original method to drop the language extension.
    def url
      _prometheus_original_url.sub(Localization::LANG_END_RE, '')
    end

    alias_method :_prometheus_original_destination, :destination

    # Overwrites the original method to not put our output files as
    # 'index.html' in a directory called by their slug.
    def destination(dest)
      # The url needs to be unescaped in order to preserve the correct filename
      File.join(dest, CGI.unescape("#{url}.html#{@lang_ext}"))
    end

  end

end
