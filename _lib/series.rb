module Jekyll

  module ImageSeries

    COUNT = 8  # TODO: make it dynamic (= number of 'descriptions')

    NAMES = Array.new(COUNT) { |i| '%02d' % i.succ }

    PARTS = Array.new(COUNT) { |i| i.succ.to_s }.concat(%w[title teaser])

    TEASER_RE = %r{(.*?[.?!])}

    class Generator < Generator

      def generate(site)
        pages = site.pages.select { |page|
          page.data['layout'] == 'series'
        }

        Pager.generate(pages)
        Part.generate(site, pages)
      end

    end

    class Pager < Pager

      def self.generate(pages)
        pages.group_by { |page| page.lang }.each_value { |pages_by_lang|
          sorted_pages = pages_by_lang.sort_by { |page|
            page.instance_variable_get(:@dir)
          }

          sorted_pages.each_with_index { |page, index|
            page.pager = Pager.new(index + 1, sorted_pages)
          }
        }
      end

      def initialize(page, all_pages)
        super({ 'paginate' => 1 }, page, all_pages, all_pages.size)
        @all_pages = all_pages
      end

      def link_at(pos)
        @all_pages[pos - 1].instance_variable_get(:@dir)
      end

    end

    class Part < Page

      def self.generate(site, pages)
        pages.each { |page|
          PARTS.each { |part| site.pages << new(site, page, part) }
        }
      end

      def initialize(site, page, part)
        super(
          site,
          page.instance_variable_get(:@base),
          page.instance_variable_get(:@dir),
          page.name
        )

        @part = part
        data['layout'] = 'none'

        self.basename = part_name
        self.content  = part_content
      end

      private

      def part_name
        i = description_no
        i ? NAMES[i - 1] : @part
      end

      def part_content
        if i = description_no
          data['descriptions'][i - 1]
        elsif @part == 'title'
          "<notextile>#{data[@part]}</notextile>"
        elsif @part == 'teaser'
          "*#{data['subtitle']}* - #{data[@part] || content[TEASER_RE, 1]}"
        else
          data[@part]
        end
      end

      def description_no
        @part =~ /\A(\d+)\z/
        $1.to_i if $1
      end

    end

  end

end
