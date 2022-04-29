class CreateArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :archive_records do |t|
      t.string :work_id
      t.string :aip_uuid
      t.string :sip_uuid
      t.string :archive_status
      t.datetime :archived_at
      t.string :metadata_hash
      t.string :files_hash
      t.string :bag_hash

      t.timestamps
    end
  end
end
