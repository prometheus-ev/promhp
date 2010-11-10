module Jekyll

  module Navigation

    def render_navigation_level(level)
      "<ul>\n#{level.inject('') { |out, i| out << render_navigation_item(i) if i }}</ul>\n"
    end

    def render_navigation_item(item)
      path = File.join(@dir, basename)

      name = item["title_#{lang}".to_sym]
      name = "<a href=\"#{relative_url(item[:url], path)}\">#{name}</a>" if item[:url]

      active = active?(item, path[1..-1])
      content = "\n#{render_navigation_level(item[:content])}\n" if item[:content] && active

      "<li#{' class="active"' if active}>#{name}#{content}</li>\n"
    end

    def active?(item, path)
      path =~ /\A#{Regexp.escape(item[:url])}/ ||
        (blog?(path) && blog?(item[:url])) ||
        (item[:content] || []).any? { |i| active?(i, path) }
    end

    def load_navigaion
      render_navigation_level(
        YAML.load(
          ERB.new(
            File.read(
              File.join(@site.source, '_navigation.yml')
            )
          ).result(binding)
        )
      )
    end

  end

end
