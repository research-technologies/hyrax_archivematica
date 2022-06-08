module HyraxArchivematica
  module ArchiveRecordHelper
    def aip_url(archive_record)
      return nil unless archive_record.ingest_uuid.present?
      link_to archive_record.ingest_uuid, "#{HyraxArchivematica.am_protocol}://#{HyraxArchivematica.am_host}/archival-storage/#{archive_record.ingest_uuid}/", :target => "_blank"
    end
  end
end

