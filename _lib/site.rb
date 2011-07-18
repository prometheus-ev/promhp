module Jekyll

  class Site

    alias_method :_prometheus_original_process, :process

    def process
      load_environment(ENV['JEKYLL_ENV'] ||= 'local')
      config['uri'] = URI.parse(config['url'])
      _prometheus_original_process
    end

    alias_method :_prometheus_original_read, :read

    def read
      _prometheus_original_read

      if File.readable?(File.join(self.source, f = '.htaccess'))
        pages << Page.new(self, self.source, '', f)
      end
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
