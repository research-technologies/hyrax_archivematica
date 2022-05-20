require_dependency "hyrax_archivematica/app/models/hyrax_archivematica/archive_record"

module HyraxArchivematica
  module HyraxArchivematicaJobBehaviour

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

    def latest_archive_records(work_id) # Could become unwieldy?
      ArchiveRecord.where(work_id:work_id).order(created_at: :desc)
    end
    def latest_archive_record_by_file_set_id(file_set_id)
      ArchiveRecord.all.order(created_at: :desc).select { |ar| ar.file_set_ids.include? file_set_id }.first
    end

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

