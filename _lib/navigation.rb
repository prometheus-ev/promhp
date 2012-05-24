module Jekyll

  module Navigation

    def self.cache(*keys)
      (@__cache__ ||= {})[keys] ||= yield
    end

    def render_navigation_level(level)
      out = "<ul>\n"
      level.each { |item| out << render_navigation_item(item) if item }
      out << "</ul>\n"
    end

    def render_navigation_item(item)
      Navigation.cache(:navigation_item, item[:title_en], lang, @dir, @name) {
        if !external_url?(item[:url]) && Dir[File.join(site.source, "#{item[:url]}*")].empty?
          ''
        else
          path = File.join(@dir, basename)
          uri  = site.config['uri'] if data['make_absolute_urls']

          name = item["title_#{lang}".to_sym]
          name = "<a href=\"#{relative_url(item[:url], uri || path)}\">#{name}</a>" if item[:url]

          active = active?(item, path[1..-1])
          content = "\n#{render_navigation_level(item[:content])}\n" if item[:content] && active

          "<li#{' class="active"' if active}>#{name}#{content}</li>\n"
        end
      }
    end

    def active?(item, path)
      path =~ /\A#{Regexp.escape(item[:url])}/ ||
        (blog?(path) && blog?(item[:url])) ||
        (item[:content] || []).any? { |i| active?(i, path) }
    end

    def load_navigation
      data['navigation'] = render_navigation_level(Navigation.cache(:navigation, lang) {
        YAML.load(ERB.new(File.read(File.join(site.source, '_navigation.yml'))).result(binding))
      })
    end

  end

end
