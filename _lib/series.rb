module Jekyll

  module ImageSeries

    extend self

    TEASER_RE = %r{(.*?[.?!])}

    TIME_PARTS = %w[%G %V]

    TIME_FORMAT = TIME_PARTS.join('/')

    LABEL_FORMAT = TIME_PARTS.reverse.join(' / ')

    def label(dir)
      date(dir).strftime(LABEL_FORMAT)
    end

    def date(dir)
      Date.strptime(order(dir), TIME_FORMAT)
    end

    def order(dir)
      dir[%r{(?:\A|/)(\d+/\d+)/?\z}, 1]
    end

    def parts(page)
      items(page).concat(%w[row teaser])
    end

    def items(page)
      Array.new(item_count(page)) { |i| item_name(i.succ) }
    end

    def item_count(page)
      items = page.respond_to?(:data) ? page.data['descriptions'] : page.descriptions
      items ? items.size : 0
    end

    ###
    #
    def item_name(i)
      '%02d' % i
    end

    def item_num(part)
      $1.to_i if part =~ /\A(\d+)\z/
    end
    #
    ###

    class Generator < Generator

      def generate(site)
        pages = site.pages.select { |page|
          page.data['layout'] == 'series'
        }

        Pager.process(pages)
        Part.generate(site, pages)
      end

    end

    class Pager < Pager

      def self.process(pages)
        pages.group_by { |page| page.lang }.each_value { |pages_by_lang|
          sorted_pages = pages_by_lang.sort_by { |page|
            page.instance_variable_get(:@dir)
          }

          sorted_pages.each_with_index { |page, index|
            page.pager = new(index + 1, sorted_pages)
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
          ImageSeries.parts(page).each { |part|
            site.pages << new(site, page, part)
          }
        }
      end

      def initialize(site, page, part)
        super(
          site,
          page.instance_variable_get(:@base),
          page.instance_variable_get(:@dir),
          page.name
        )

        data['layout'] = 'none'

        item_num = ImageSeries.item_num(part)
        self.basename = item_num ? ImageSeries.item_name(item_num) : part

        self.content = if item_num
          data['descriptions'][item_num - 1]
        else
          locals = {
            :url        => File.join('<!--#echo var="url_root" -->', @dir),
            :title      => data['title'],
            part.to_sym => case part
              when 'row'
                items = ImageSeries.items(self)
                extra, size = items.dup, items.size

                String(data['repeat']).split(/[,\s]+/)
                  .map { |i| i.to_i }.uniq[0, size]
                  .delete_if { |i| i < 1 || i > size }
                  .each_with_index.sort.reverse_each { |i, j|
                    items[size + j] = extra.delete_at(i - 1)
                  }

                items.concat(extra.shuffle!)
              when 'teaser'
                subtitle = data['subtitle'].to_s.strip

                teaser = data[part] || content[TEASER_RE, 1]
                teaser = "*#{subtitle}* - #{teaser}" unless subtitle.empty?
                teaser
            end
          }

          %Q{<%= include_file('series/#{part}.html', #{locals.inspect}) %>}
        end
      end

    end

  end

end
