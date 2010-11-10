module Jekyll

  class Pagination

    alias_method :_prometheus_original_generate, :generate

    def generate(site)
      site.pages.dup.each do |page|
        file = File.join(page.instance_variable_get(:@dir), page.name)[1..-1]
        paginate(site, page) if Pager.pagination_enabled?(site.config, file)
      end
    end

    alias_method :_prometheus_original_paginate, :paginate

    def paginate(site, page)
      def page.dir; @dir; end
      Page.send(:alias_method, :dir=, :_prometheus_paginate_dir=)

      _prometheus_original_paginate(site, page)
    ensure
      class << page; remove_method :dir; end
      Page.send(:alias_method, :dir=, :_prometheus_original_dir=)
    end

  end

  class Pager

    def link_at(pos)
      pos == 1 ? 'blog' : "page#{pos}"  # TODO: Make these dynamic.
    end

    def first_link
      link_at(1) if page > 1
    end

    def last_link
      link_at(total_pages) if page < total_pages
    end

    def previous_link
      link_at(previous_page) if previous_page
    end

    def next_link
      link_at(next_page) if next_page
    end

    alias_method :_prometheus_original_to_liquid, :to_liquid

    def to_liquid
      _prometheus_original_to_liquid.merge(
        :first_link    => first_link,
        :last_link     => last_link,
        :previous_link => previous_link,
        :next_link     => next_link
      )
    end

  end

end
