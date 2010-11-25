module Jekyll

  class AuthorGenerator < Generator

    def generate(site)
      site.config['authors'] = YAML.load_file(File.join(site.source, '_authors.yml'))
      author_pages(site)
    end

    def get_posts(site, author, lang)
      posts = []
      site.posts.each { |p| posts << p if p.data['author'] == author && p.lang == lang }
      posts.sort
    end

    def author_pages(site)
      return unless site.config['authors']
      Localization::LANGUAGES.each { |lang|
        site.config['authors'].each { |a|
          a[1]['posts'] = get_posts(site, a[0], lang)
          site.pages << AuthorPage.new(site, site.source, '/blog/author/', "#{a[0].downcase}.#{lang}.html",
            {
              'content' => a[1],
              'author'  => a[0],
              'layout'  => 'author'
            }
          )
        }
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
