module Jekyll

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

end
