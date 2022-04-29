module HyraxArchivematica
  class ArchiveRecord < ApplicationRecord
    serialize :file_set_ids, Array

    STATUS_ARCHIVE_INITIALISED = 'archive_initialised'.freeze
    STATUS_BAG_CREATED = 'bag_created'.freeze
    STATUS_BAG_CHECKED = 'bag_checked'.freeze
    STATUS_BAG_ZIPPED = 'bag_zipped'.freeze
    STATUS_BAG_TRANSFERRED = 'bag_transferred'.freeze
    STATUS_AM_TRANSFERRED = 'am_transferred'.freeze
    STATUS_AM_INGESTED = 'am_ingested'.freeze
    STATUS_ARCHIVE_COMPLETE = 'archive_complete'.freeze
    STATUS_ERROR = 'error'.freeze
  end
end
