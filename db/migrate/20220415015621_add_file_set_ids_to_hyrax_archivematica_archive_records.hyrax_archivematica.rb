class AddFileSetIdsToHyraxArchivematicaArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_archivematica_archive_records, :file_set_ids, :text
  end
end
