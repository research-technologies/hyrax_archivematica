# frozen_string_literal: true
#require_dependency "hyrax_archivematica/app/jobs/hyrax_archivematica_job_behaviour"

module HyraxArchivematica
  class ArchivematicaTransferJob < Gush::Job
    include HyraxArchivematica::HyraxArchivematicaJobBehaviour

    def perform
      prev_job_output = payloads.first[:output] 
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id])
      # TODO rescue AR not being found
      start_am_transfer
    end

    def start_am_transfer
      STDERR.puts "We wll now start the transfer of the bag in transfer_source: #{remote_bag_location} using the transfer source UUID #{HyraxArchivematica.am_transfer_source_uuid} ... "
    end
   
    def remote_bag_location
      File.join(am_transfer_source_dir,bag_zip)
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

  end
end
