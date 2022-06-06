module HyraxArchivematica
  # Call the approve transfer archivematica api
  class ApproveTransferJob < BaseJob
    include HyraxArchivematica::ArchiveRecordBehaviour

    # Approve transfer
    #  sleep 10 seconds to allow for completion of StartTransfer
    # payloads.first[:output] [Hash] required params
    def perform
      sleep(10)
      prev_job_output = payloads.first[:output] 
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id])
      @response = HyraxArchivematica::Api::ApproveTransfer.new(params: payloads.first[:output]).request
      act_on_status
    end

    private

      # If response message is success, return params for next job
      def act_on_ok
        if body['message'] == 'Approval successful.'
          output(
            event: 'success',
            message: message_text,
            uuid: body['uuid'],
            accession: payloads.first[:output][:accession],
            archive_record_id: @archive_record.id
          )
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_APPROVAL_SUCCESS, transfer_uuid: body['uuid']})
        else
          Rails.logger.error("Approve transfer Job failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_AM_APPROVAL_FAILED})
          fail!
        end
      end
  end
end
