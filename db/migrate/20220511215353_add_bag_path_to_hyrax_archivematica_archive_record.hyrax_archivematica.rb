class AddBagPathToHyraxArchivematicaArchiveRecord < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_archivematica_archive_records, :bag_path, :string
  end
end
