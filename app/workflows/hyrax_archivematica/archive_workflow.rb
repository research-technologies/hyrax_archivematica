
module HyraxArchivematica
  class ArchiveWorkflow < Gush::Workflow
#    def configure(user, work_id=nil, file_set_id=nil,force=false)
    def configure(params)
      # Assess work for archiving and scp the bag to the archviematia host
      run HyraxArchivematica::AssessForArchivingJob, params: params , queue: 'archive'
      run HyraxArchivematica::CreateBagJob, params: {user: params[:user]}, after: HyraxArchivematica::AssessForArchivingJob, queue: 'archive'
      run HyraxArchivematica::ScpBagJob, after: HyraxArchivematica::CreateBagJob, queue: 'archive'
      # Use Archivematica API to transfer, approve and check status
      run HyraxArchivematica::ArchivematicaTransferJob, after: HyraxArchivematica::ScpBagJob, queue: 'archive'
      run HyraxArchivematica::ApproveTransferJob, after: HyraxArchivematica::ArchivematicaTransferJob, queue: 'archive'
      run HyraxArchivematica::TransferStatusJob, after: HyraxArchivematica::ApproveTransferJob, queue: 'archive'
      run HyraxArchivematica::IngestStatusJob, after: HyraxArchivematica::TransferStatusJob, queue: 'archive'

    end
  end
end
