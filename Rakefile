require 'benchmark'

GEM_NAME = 'jekyll'
gem GEM_NAME  # fail early

BASE = File.expand_path('..', __FILE__)
CONF = File.join(BASE, '_config')
SITE = File.join(BASE, '_site')
ENVS = Dir[File.join(CONF, '*.yml')].map { |file| File.basename(file, '.yml') }

task :default => [:setup, :build]

desc "Set up build environment"
task :setup do
  unless File.exist?(local = File.join(CONF, 'local.yml'))
    if ENVS.include?(env = ENV['JEKYLL_ENV'])
      ln_s env + '.yml', local
    else
      cp local + '.sample', local
    end
  end
end

desc "Build the site"
task :build do
  warn 'Elapsed: %dm%.2fs' % Benchmark.realtime { build }.divmod(60)
end

desc "Build preview for start page with NUM's (yyyy/ww) image series"
task :series_preview do
  case num = ENV['NUM'] || Date.today.strftime('%G/%V')
    when /\A\d{4}\/\d{2}\z/
      # ok
    when /\A(\d{2})\/(\d{4})\z/
      num = "#{$2}/#{$1}"
    else
      abort "illegal value: #{num}"
  end

  abort "image series not found: #{num}" if Dir[File.join(BASE, 'series', num, 'index.*')].empty?

  mkdir_p src = site_path('src')

  inc, exc = %w[_* index.* .htaccess images inc javascripts stylesheets],
             %w[_posts _site*]

  # copy required files to temp location
  Dir.chdir(BASE) {
    cp_r FileList.new(*inc) { |fl| fl.exclude(*exc) }, src

    %W[files/images files/icons series/#{num}].each { |path|
      mkdir_p target = File.join(src, File.dirname(path))
      cp_r path, target
    }
  }

  # replace ${DATE_LOCAL} in 'set var="current_series"'
  # (in _layouts/default.html) with supplied YEAR/WEEK
  File.open(File.join(src, '_layouts', 'default.html'), 'r+') { |f|
    content = f.read.sub('${DATE_LOCAL}', num)

    f.truncate(0)
    f.rewind

    f.print content
  }

  # run jekyll with <temp location> <dest location>
  build(src)
end

desc "Remove current site"
task :clean do
  rm_rf site_paths
end

desc "Tag release"
task :tag do
  sh 'git', 'tag', "cl-#{Time.now.to_f}"
end

ENVS.each { |env|
  desc "Run following tasks in #{env} environment"
  task env do
    ENV['JEKYLL_ENV'] = env
  end
}

def site_paths
  [nil, 'tmp', 'old'].map { |ext| site_path(ext) }
end

def site_path(ext = nil)
  "#{SITE}#{'.' if ext}#{ext}"
end

def build(src = nil)
  site, tmp, old = site_paths

  argv, args = ARGV.dup, [tmp]
  args.unshift(src) if src

  ARGV.replace(args)

  load Gem.bin_path(GEM_NAME, GEM_NAME)

  mv site, old if File.exist?(site)
  mv tmp, site
ensure
  [old, src].each { |dir| rm_rf dir if dir }
  ARGV.replace(argv)
end
