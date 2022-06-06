module HyraxArchivematica
  # call the ingest status archivematica api
  class IngestStatusJob < BaseJob
    attr_accessor :ingest_status

    # Get ingest status
    # payloads.first[:output] [Hash] required params
    def perform
      prev_job_output = payloads.first[:output]
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id])
      @response = HyraxArchivematica::Api::IngestStatus.new(params: payloads.first[:output]).request
      @ingest_status = body['status'] if body['status']
      act_on_status
    end

    private

      # If response message is COMPLETE, return params for next job
      def act_on_ok
        case ingest_status
        when 'COMPLETE'
          output(event: 'success',
                 message: message_text,
                 uuid: body['uuid'],
                 accession: payloads.first[:output][:accession], 
                 archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_ARCHIVE_COMPLETE, ingest_uuid: body['uuid']})
        when 'PROCESSING'
          output(event: 'retry', message: message_text, archive_record_id: @archive_record.id)
          Rails.logger.error("Job was sent for a retry with: #{message_text}")
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_INGEST_IN_PROGRESS, ingest_uuid: body['uuid']})
          fail!
        when 'USER_INPUT'
          # @todo send email
          Rails.logger.error("Job was sent for a retry with: #{message_text}")
          output(event: 'retry', message: message_text, archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_INGEST_WAITING, ingest_uuid: body['uuid']})
          fail!
        else
          Rails.logger.error("Ingest status Job failed with: #{message_text}")
          output(event: 'failed', message: message_text, archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_INGEST_FAILED, ingest_uuid: body['uuid']})
          fail!
        end
      end
  end
end
