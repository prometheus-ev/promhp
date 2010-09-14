task :default => :build

desc "Build the site"
task :build do
  name = ENV['USE_FORK'] ? "#{ENV['USE_FORK']}-jekyll" : 'jekyll'
  gem name  # fail early

  site, tmp, old = site_paths

  begin
    argv = ARGV.dup
    ARGV.replace([tmp])

    load Gem.bin_path(name)

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

def site_paths
  site = File.expand_path('../_site', __FILE__)
  [site, "#{site}.tmp", "#{site}.old"]
end
