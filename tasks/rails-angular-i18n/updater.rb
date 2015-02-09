require 'nokogiri'
require 'open-uri'
require 'versionomy'
require 'pathname'
require 'tempfile'

module RailsAngularI18n
  class Updater
    BASE_URL = 'https://code.angularjs.org'
    ROOT_PATH = Pathname.new('vendor/assets/javascripts/angular-i18n')

    def initialize
    end

    def base_path
      ROOT_PATH
    end

    def update_js!
      if latest_version >= current_gem_version
        clean
        download_files
        update_version_to(latest_version)
      end
    end

    def current_gem_version
      raise NotImplementedError
    end

    def available_versions
      upstream_versions.find_all {|v| own_version(v) }
    end

    def latest_version
      available_versions.last
    end

    def version_constant_name
      "VERSION"
    end

    private

    def clean
      base_path.children.each do |f|
        f.delete if f.file?
      end
    end

    def update_version_to(version)
      version_file = Pathname.new('lib/rails-angular-i18n/version.rb')
      content = version_file.read
      version_line = content.lines.find { |l| l =~ /^\s+#{version_constant_name}/ }

      new_version_line = version_line.gsub(/"[^"]+"/, %Q{"#{version}"})
      version_file.open('w+') do |f|
        f.write content.gsub(version_line, new_version_line)
      end
    end

    def upstream_versions
      @upstream_versions ||= Nokogiri::HTML.parse(open(BASE_URL)).
        css('a').map { |e| Versionomy.parse e.text[0..-2] rescue nil }.compact.sort
    end

    def self.update_js!
      self.new.update_js!
    end

    def download_files
      url = BASE_URL + "/" + latest_version.to_s + "/i18n"
      Nokogiri::HTML.parse(open(url)).
        css('a').

        map{|a| a[:href] =~ /angular-locale_[a-z]*\.js$/ ? a : nil }.compact.

        each do |a|
          download_file(a[:href], url)
        end
    end

    def download_file(file, url)
      full_url = url + "/" + file
      full_path = base_path.join(file)
      full_path.open('w+') do |f|
        f.write open(full_url).read
      end
    end
  end
end
