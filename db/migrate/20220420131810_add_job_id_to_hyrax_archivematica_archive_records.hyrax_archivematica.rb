class AddJobIdToHyraxArchivematicaArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_archivematica_archive_records, :job_id, :string
  end
end
