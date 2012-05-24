module Jekyll

  class Site

    alias_method :_prometheus_original_process, :process

    def process
      load_environment(ENV['JEKYLL_ENV'] ||= 'local')

      config.update(
        'authors' => YAML.load_file(File.join(source, '_authors.yml')),
        'uri'     => URI.parse(config['url'])
      )

      if Object.const_defined?(:Encoding) && encoding = config['encoding']
        Encoding.default_external = encoding
      end

      _prometheus_original_process
    end

    alias_method :_prometheus_original_read, :read

    def read
      _prometheus_original_read

      if File.readable?(File.join(self.source, f = '.htaccess'))
        pages << Page.new(self, self.source, '', f)
      end
    end

    alias_method :_prometheus_original_reset, :reset

    def reset
      _prometheus_original_reset
      @_site_payload_memo = nil
    end

    alias_method :_prometheus_original_site_payload, :site_payload

    def site_payload
      @_site_payload_memo ||= _prometheus_original_site_payload
    end

    def add_payload(payload)
      config.update(payload)
      set_payload(payload) if @_site_payload_memo
    end

    def set_payload(payload)
      site_payload['site'].update(payload)
    end

    def get_payload(key)
      site_payload['site'][key]
    end

    private

    def load_environment(env)
      warn "Environment: #{env}"

      if File.readable?(file = File.join(source, '_config', "#{env}.yml"))
        config.update(YAML.load_file(file))
        config['env'] = env
      else
        warn "Config file not found: #{file}"
      end
    end

  end

end
