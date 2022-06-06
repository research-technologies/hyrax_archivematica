module HyraxArchivematica
  module ArchiveRecordBehaviour
    extend ActiveSupport::Concern

    def calculate_md5(file,chunk=4096)
      # Digest::MD5.hexdigest(File.read(file))
      # dontnakaballsiyit
      md5 = Digest::MD5.new
      buf = ""
      file = File.new(file)
      while buf = file.read(chunk)
        md5.update(buf)
      end
      md5.hexdigest
    end

    def archive_records(work_id) # Could become unwieldy?
      ArchiveRecord.where(work_id:work_id).order(created_at: :desc)
    end

    # return the latest archive record that does not have a transfer_uuid
    # so we can assume has not gotten to the ArchivematicaTransferJob and has no transfer_uuid
    def not_started_archive_records(work_id)
      ArchiveRecord.where(work_id:work_id, transfer_uuid: nil).order(created_at: :desc)
    end
    
    # return the latest archive record that does not have a transfer_uuid
    # so we can assume has not gotten to the ArchivematicaTransferJob and has no transfer_uuid
    def active_archive_records(work_id)
      ArchiveRecord.where(work_id:work_id).where.not(archive_status: HyraxArchivematica::Constants::STATUS_ARCHIVE_COMPLETE).order(created_at: :desc)
    end

    # returns the latest archive_Record that has the given file_set_id
    # only for use when we don't have access to the work id and need to get this from the AR
    # i.e. triggered by a file that has been deleted so is no longer associated with the parent work
    # The `all` is ugly as hell
    def latest_archive_record_by_file_set_id(file_set_id)
      ArchiveRecord.all.order(created_at: :desc).select { |ar| ar.file_set_ids.include? file_set_id }.first
    end
    
    def bag_path
      @archive_record.bag_path
    end

    def bag_zip
      File.basename(bag_path)
    end

    def bag_hash
      @archive_record.bag_hash
    end


    #TODO find a suitable home for this stuff
    def am_host
      HyraxArchivematica.am_host
    end

    def am_user
      HyraxArchivematica.am_user
    end

    def am_ssh_key
      HyraxArchivematica.am_ssh_key
    end

    def am_ssh_user
      HyraxArchivematica.am_ssh_user
    end

    def am_transfer_source_dir
      HyraxArchivematica.am_transfer_source_dir
    end


  end
end
