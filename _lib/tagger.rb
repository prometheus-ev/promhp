module Jekyll

  class Tagger

    alias_method :_prometheus_original_generate_tag_pages, :generate_tag_pages

    def generate_tag_pages(site)
      tags, original_tags = [], site.tags.dup

      Localization::LANGUAGES.each { |lang|
        original_tags.each { |tag, posts|
          posts = posts.select { |p| p.lang == lang }
          tags << ["#{tag}.#{lang}", posts]
        }
      }

      site.tags = tags
      _prometheus_original_generate_tag_pages(site)
    ensure
      site.tags = original_tags if original_tags
    end

  end

end
