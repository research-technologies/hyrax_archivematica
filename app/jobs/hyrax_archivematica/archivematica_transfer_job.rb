# frozen_string_literal: true
#require_dependency "hyrax_archivematica/app/jobs/hyrax_archivematica_job_behaviour"

module HyraxArchivematica
  class ArchivematicaTransferJob < BaseJob
    include HyraxArchivematica::ArchiveRecordBehaviour

    def perform
      prev_job_output = payloads.first[:output] 
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id])
      # TODO rescue AR not being found
      @transfer_type = 'zipped bag'
      @response = HyraxArchivematica::Api::StartTransfer.new(params: {path: remote_bag_location, type: @transfer_type, am_ts: HyraxArchivematica.am_transfer_source_uuid}).request
      act_on_status
    end

    private

      # If response message is success, return params for next job
      def act_on_ok
        if body['message'] == 'Copy successful.'
          output(
            event: 'success',
            message: message_text,
            directory: body['path'].split('/').last,
            type: @transfer_type,
            accession: payloads.first[:output][:accession],
            archive_record_id: @archive_record.id
          )
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_STARTED})
        else
          Rails.logger.error("Job was failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_FAILED})
          fail!
        end
      end

    def remote_bag_location
      File.join(am_transfer_source_dir,bag_zip)
    end

  end
end
