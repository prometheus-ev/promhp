module Jekyll

  class AuthorGenerator < Generator

    def generate(site)
      @authors = site.config['authors'] = YAML.load_file(File.join(site.source, '_authors.yml'))
      generate_author_pages(site)
      generate_author_index(site)
    end

    def get_posts(site, author, lang)
      site.posts.select { |p|
        p.data['author'] == author && p.lang == lang
      }.sort.reverse
    end

    def generate_author_pages(site)
      return unless @authors
      Localization::LANGUAGES.each { |lang|
        @authors.each { |author, data|
          data['posts'] = get_posts(site, author, lang)
          site.pages << AuthorPage.new(site, site.source, '/blog/author/', "#{author.downcase}.#{lang}.html",
            {
              'content' => data,
              'author'  => author,
              'layout'  => 'author'
            }
          )
        }
      }
    end

    def generate_author_index(site)
      Localization::LANGUAGES.each { |lang|
        @authors.each { |author, data| data['post_count'] = get_posts(site, author, lang).size }

        site.pages << AuthorPage.new(site, site.source, '/blog/author/', "index.#{lang}.html",
          {
            'content' => @authors,
            'layout'  => 'author_index'
          }
        )
      }
    end

  end

  class AuthorPage < TagPage

    def initialize(site, base, dir, name, data = {})
      super(site, base, dir, name, data)
      self.data.delete('tag')
    end

  end

end
