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
      page_title_for(page, head)
    end

    def page_title_for(page, head = false)
      parts, title = page.url.sub(/\A\//, '').split('/'), page.title

      case parts.first
        when /\A\d+\z/
          pre = "#{t('prometheus Blog', 'prometheus-Blog')} - " if head
          "#{pre}#{title}"
        when 'series'
          num = parts.values_at(-2, -3).map { |i| i.to_i }.join(' / ')
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

    def author(post)
      author = post.is_a?(Jekyll::Post) ? post.data['author'] : post.author
      if url = @site.authors[author]
        %Q{<a href="#{r('blog/author/' + author.downcase)}">#{author}</a>}
      else
        author
      end
    end

    def disqus(post)
      if post.is_a?(Symbol)
        post, type = page, post
      else
        type = 'embed'
        vars = <<-EOT
  var disqus_identifier = '#{disqus_identifier(post)}';
  var disqus_url        = '#{@site.url + post.url}';
  var disqus_title      = '#{page_title_for(post).gsub(/'/, '&apos;')}';
        EOT
      end

      _ = <<-EOT
<script type="text/javascript">
  var disqus_shortname  = '#{@site.disqus}';
  var disqus_developer  = #{@site.env == 'live' ? 0 : 1};

#{vars}

  var disqus_config = function() {
    this.language = '#{post.lang == 'de' ? 'de_formal' : post.lang}';
  };

  (function() {
    var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
    dsq.src = 'http://' + disqus_shortname + '.disqus.com/#{type}.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
  })();
</script>
      EOT
    end

    def disqus_identifier(post)
      @site.env + post.id.sub(/\.[a-z]{2}\z/, '')
    end

    def record_count
      %Q{<span id="record_count">#{t('more than 750,000', 'mehr als 750.000')}</span>}
    end

    def source_count
      %Q{<span id="source_count">#{t('60', '60')}</span>}
    end

    def license_count
      %Q{<span id="license_count">#{t('over 120', 'über 120')}</span>}
    end

    def user_count
      %Q{<span id="user_count">#{t('over 10,000', 'über 10.000')}</span>}
    end

  end

end
