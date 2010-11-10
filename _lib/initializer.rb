module Jekyll

  class Initializer < Generator

    def generate(site)
      read_authors(site)
    end

    def read_authors(site)
      site.config['authors'] = YAML.load(File.read(File.join(site.source, '_authors.yml')))
    end

  end

end
