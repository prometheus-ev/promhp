# encoding: utf-8

module Jekyll

  module Filters

    include Helpers

    def r(str, absolute = page.make_absolute_urls)
      relative_url(str, absolute ? site.uri : page.url)
    end

    def p(*path)
      pandora_url(path, page, site)
    end

    def canonical_url(lang = page.lang)
      canonical_url_for(page.url, lang)
    end

    def canonical_url_for(url, lang = nil)
      File.join(site.url, !site.prefix_lang ? url_lang(url, lang) :
        [lang, url.sub(/(?:\.html)?#{Localization::LANG_END_RE}/, '')].compact)
    end

    def page_title(head = false)
      page_title_for(page, head)
    end

    def page_title_for(page, head = false)
      title = page.title.dup if page.title
      parts = page.url.sub(/\A\//, '').split(sep = '/')

      if blog?(page.url)
        suffix = t('prometheus Blog', 'prometheus-Blog') if head

        if @paginator
          title, page = suffix || title, @paginator.page
          title << " (#{t('Page', 'Seite')} #{page})" if page > 1
        else
          title ||= if parts[0] == site.tag_page_dir
            page.tag ? %Q{Tag "#{page.tag}"} : 'Tags'
          elsif parts[1] == 'author'
            page.author ? %Q{#{t('Author', 'Autor')} "#{page.author}"} : t('Authors', 'Autoren')
          end

          title << ' - ' << suffix if suffix
        end
      elsif parts[0] == 'series'
        title.insert(0, "#{t('Image series', 'Bildserie')} #{ImageSeries.label(parts[1, 2].join(sep))}: ")
      end

      title
    end

    def stylesheet_link(name, media = 'all', id = nil)
      %Q{<link rel="stylesheet" type="text/css" href="#{asset_path_for("stylesheets/#{name}.css")}" media="#{media}"#{%Q{ id="#{id}"} if id} />}
    end

    def javascript_link(name)
      %Q{<script src="#{asset_path_for("javascripts/#{name}.js")}" type="text/javascript"></script>}
    end

    def asset_path_for(file)
      "#{r(file)}?#{File.mtime(file).to_i.to_s}"
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
      if url = site.authors[author]
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
  var disqus_url        = '#{site.url + post.url}';
  var disqus_title      = '#{page_title_for(post).gsub(/'/, '&apos;')}';
        EOT
      end

      _ = <<-EOT
<script type="text/javascript">
  var disqus_shortname  = '#{site.disqus}';
  var disqus_developer  = #{site.env == 'live' ? 0 : 1};

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
      site.env + post.id.sub(Localization::LANG_END_RE, '')
    end

    def record_count
      %Q{<span id="record_count">#{t('more than 820,000', 'mehr als 820.000')}</span>}
    end

    def source_count
      %Q{<span id="source_count">#{t('60', '60')}</span>}
    end

    def license_count
      %Q{<span id="license_count">#{t('over 120', 'über 120')}</span>}
    end

    def user_count
      %Q{<span id="user_count">#{t('over 11,000', 'über 11.000')}</span>}
    end

    def tagged_posts(tag, num = 0)
      posts, cnt = [], 0

      local_posts.each { |post|
        if post.tags.include?(tag)
          posts << post
          break if num > 0 && (cnt += 1) >= num
        end
      }

      posts
    end

    def news_posts(num = 4)
      tagged_posts('news', num)
    end

  end

end
