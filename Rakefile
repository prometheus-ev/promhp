GEM_NAME = 'jekyll'

task :default => :build

desc "Build the site"
task :build do
  gem GEM_NAME  # fail early

  site, tmp, old = site_paths

  begin
    argv = ARGV.dup
    ARGV.replace([tmp])

    load Gem.bin_path(GEM_NAME)

    mv site, old if File.exist?(site)
    mv tmp, site
  ensure
    rm_rf old if old
    ARGV.replace(argv)
  end
end

desc "Remove current site"
task :clean do
  rm_rf site_paths
end

desc "Tag release"
task :tag do
  sh 'git', 'tag', "cl-#{Time.now.to_f}"
end

Dir['_config/*.yml'].each { |file|
  env = File.basename(file, '.yml')

  desc "Run following tasks in #{env} environment"
  task env do
    ENV['JEKYLL_ENV'] = env
  end
}

def site_paths
  site = File.expand_path('../_site', __FILE__)
  [site, "#{site}.tmp", "#{site}.old"]
end
