class CreateHyraxArchivematicaArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :hyrax_archivematica_archive_records do |t|
      t.string :work_id
      t.string :ingest_uuid
      t.string :transfer_uuid
      t.string :archive_status
      t.datetime :archived_at
      t.string :metadata_hash
      t.string :files_hash
      t.string :bag_hash
      t.string :bag_path
      t.text :file_set_ids

      t.timestamps
    end
  end
end
