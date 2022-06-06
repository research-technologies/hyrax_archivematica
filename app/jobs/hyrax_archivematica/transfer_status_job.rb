module HyraxArchivematica
  # call the transfer status archivematica api
  class TransferStatusJob < BaseJob
    attr_accessor :transfer_status

    # Get transfer status
    # payloads.first[:output] [Hash] required params
    def perform
      prev_job_output = payloads.first[:output] 
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id])
      @response = HyraxArchivematica::Api::TransferStatus.new(
        params: prev_job_output
      ).request
      @transfer_status = body['status'] if body['status']
      act_on_status
    end

    private

      # If response message is COMPLETE, return params for next job
      def act_on_ok
        case transfer_status
        when 'COMPLETE'
          output(
            event: 'success',
            message: message_text,
            uuid: body['sip_uuid'],
            accession: payloads.first[:output][:accession],
            archive_record_id: @archive_record.id
          )
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_SUCCESS, ingest_uuid: body['sip_uuid'], transfer_uuid: body['uuid']})
        when 'PROCESSING'
          output(event: 'retry', message: message_text, archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_IN_PROGRESS, ingest_uuid: body['sip_uuid'], transfer_uuid: body['uuid']})
          fail!
        when 'USER_INPUT'
          # @todo send email
          output(event: 'retry', message: message_text, archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_WAITING, ingest_uuid: body['sip_uuid'], transfer_uuid: body['uuid']})
          fail!
        else
          output(event: 'failed', message: message_text, archive_record_id: @archive_record.id)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_TRANSFER_FAILED, ingest_uuid: body['sip_uuid'], transfer_uuid: body['uuid']})
          fail!
        end
      end
  end
end
