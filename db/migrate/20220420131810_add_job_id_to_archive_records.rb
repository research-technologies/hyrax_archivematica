class AddJobIdToArchiveRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :archive_records, :job_id, :string
  end
end
