module Jekyll

  class Site

    alias_method :_prometheus_original_process, :process

    def process
      load_environment(ENV['JEKYLL_ENV'] ||= 'local')
      _prometheus_original_process
    end

    private

    def load_environment(env)
      warn "Environment: #{env}"

      if File.readable?(file = File.join(source, '_config', "#{env}.yml"))
        config.update(YAML.load_file(file))
        config[:env] = env
      else
        warn "Config file not found: #{file}"
      end
    end

  end

end
