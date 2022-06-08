# frozen_string_literal: true

class HyraxArchivematica::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc 'This generator installs Hyrax Archivematica'

  def banner
    say_status("info", "Generating Hyrax Archivematica installation", :blue)
  end

  def add_css
    ['css', 'scss', 'sass'].map do |ext|
      file = "app/assets/stylesheets/application.#{ext}"
      next unless File.exist?(file)

      file_text = File.read(file)
      css = "*= require 'hyrax_archivematica/application'"
      next if file_text.include?(css)

      insert_into_file file, before: /\s\*= require_self/ do
        "\s#{css}\n"
      end
    end
  end

  def mount_route
    route "mount HyraxArchivematica::Engine, at: '/'"
  end

  def create_config
    copy_file 'config/initializers/hyrax_archivematica.rb', 'config/initializers/hyrax_archivematica.rb' unless File.exists?('config/initializers/hyrax_archivematica.rb')
  end

  def create_helpers
    helper = '  include HyraxArchivematica::ArchiveRecordHelper'
    unless File.read('app/helpers/hyrax_helper.rb').include? helper
      inject_into_file 'app/helpers/hyrax_helper.rb', after: "Hyrax::HyraxHelperBehavior\n" do
        "#{helper}\n"
      end
    end
  end

end
