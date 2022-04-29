class AddFileSetIdsToArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :archive_records, :file_set_ids, :text
  end
end
