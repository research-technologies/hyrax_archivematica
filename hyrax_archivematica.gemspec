Gem::Specification.new do |s|
  s.name        = 'hyrax_archivematica'
  s.version     = '0.0.1'
  s.summary     = "Hyrax / Archivematica integration gem"
  s.description = "Hyrax / Archivematica integration gem. Bags up hyrax works and transfers them to archivematica, then manages rtansfer and ingest of item, keeps a dashboard showing progress and finally records the AIP UUID"
  s.authors     = ["Rory McNicholl"]
  s.email       = 'rory.mcnicholl@london.ac.uk'
  s.files       = ["lib/hyrax_archivematica.rb", "lib/hyrax_archivematica/engine.rb", "lib/hyrax_archivematica/api.rb", "config/routes.rb", "app/models/hyrax_archivematica/archive_record.rb", "app/controllers/hyrax_archivematica/application_controller.rb", "app/controllers/hyrax_archivematica/archives_controller.rb", "app/workflows/archive_workflow.rb", "db/migrate/20220412100839_create_archive_records.hyrax_archivematica.rb", "20220415015621_add_file_set_ids_to_archive_records.hyrax_archivematica.rb", "20220420131810_add_job_id_to_archive_records.hyrax_archivematica.rb", "20220511215353_add_bag_path_to_archive_record.hyrax_archivematica.rb"]
  s.homepage    =
    'https://rubygems.org/gems/hyrax_archivematica'
  s.license       = 'Apache2.0'

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 5.1.6"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 5.1.6"])
  end
end
