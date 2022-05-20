module HyraxArchivematica
  class ArchiveRecord < ApplicationRecord
    serialize :file_set_ids, Array

  end
end
