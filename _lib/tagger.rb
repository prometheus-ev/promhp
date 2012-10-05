module Jekyll

  class Tagger

    alias_method :_prometheus_original_generate_tag_pages, :generate_tag_pages

    def generate_tag_pages
      site.tags, original_tags = tags = [], site.tags.dup

      Localization::LANGUAGES.each { |lang| original_tags.each { |tag, posts|
        tags << ["#{tag}.#{lang}", posts.select { |post| post.lang == lang }]
      } }

      _prometheus_original_generate_tag_pages
    ensure
      site.tags = original_tags if original_tags
    end

  end

end
