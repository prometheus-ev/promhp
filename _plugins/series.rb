module Jekyll

  class ImageSerializer < Generator

    def generate(site)
      series = site.pages.map { |p| p if p.data['layout'] == 'series' }.compact
      series.each { |p|
        ImageSeris.parts.each { |part|
          site.pages << ImageSeris.new(
            site,
            p.instance_variable_get(:@base),
            p.instance_variable_get(:@dir),
            p.name, part
          )
        }
      }
    end

  end

  class ImageSeris < Page

    ImageSerisParts = %w{title teaser} + (1..8).map { |i| "description_#{i}" }

    def initialize(site, base, dir, name, part)
      @part = part
      super(site, base, dir, name)
      self.data['layout'] = 'none'
      self.basename = part_name
      self.content = part_content
    end

    def self.parts
      ImageSerisParts
    end

    def part_name
      if nr = description_nr
        "0#{nr}"
      else
        @part
      end
    end

    def description_nr
      @part =~ /\Adescription_(\d)\z/
      return $1 ? $1.to_i : $1
    end

    def part_content
      if nr = description_nr
        self.data['descriptions'][nr - 1]
      elsif @part == 'title'
        "<notextile>#{self.data[@part]}</notextile>"
      elsif @part == 'teaser'
        teaser
      else
        self.data[@part]
      end
    end

    def teaser
      self.data['teaser'] || @content.match(/([^!?.]*[.?!])/)[1]
    end

  end

end
