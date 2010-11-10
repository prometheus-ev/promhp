module Jekyll

  module Filters

    include Helpers

    def r(str)
      relative_url(str, page.url)
    end

    def p(*path)
      pandora_url(path, site, page)
    end

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

    def paginator_first_link
      if href = @paginator.first_link
        %Q{<a href="#{r(href)}"><div class="icon_first"></div></a>}
      else
        '<div class="icon_first inactive"></div>'
      end
    end

    def paginator_last_link
      if href = @paginator.last_link
        %Q{<a href="#{r(href)}"><div class="icon_last"></div></a>}
      else
        '<div class="icon_last inactive"></div>'
      end
    end

    def paginator_previous_link
      if href = @paginator.previous_link
        %Q{<a href="#{r(href)}"><div class="icon_prev"></div></a>}
      else
        '<div class="icon_prev inactive"></div>'
      end
    end

    def paginator_next_link
      if href = @paginator.next_link
        %Q{<a href="#{r(href)}"><div class="icon_next"></div></a>}
      else
        '<div class="icon_next inactive"></div>'
      end
    end

    def paginator_navigation
      [
        paginator_first_link, paginator_previous_link,
        t('Page', 'Seite'),  @paginator.page,  # TODO: Make this dynamic?
        t('of',   'von'),    @paginator.total_pages,
        paginator_next_link,  paginator_last_link
      ].join(' ')
    end

    def tag_url(tag, dir = site.tag_page_dir)
      r(File.join(dir, u(tag)))
    end

    alias_method :_prometheus_original_tags, :tags

    def tags(obj)
      obj = { 'tags' => obj.tags } if obj.is_a?(Jekyll::Post)
      _prometheus_original_tags(obj)
    end

  end

end
