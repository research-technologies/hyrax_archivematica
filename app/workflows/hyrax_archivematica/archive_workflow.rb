# Why am I needing to require these? Which rails law am I not obeying?
#require_dependency "hyrax_archivematica/app/jobs/assess_for_archiving_job"
#require_dependency "hyrax_archivematica/app/jobs/create_bag_job"
#require_dependency "hyrax_archivematica/app/jobs/scp_bag_job"
#require_dependency "hyrax_archivematica/app/jobs/archivematica_transfer_job"

module HyraxArchivematica
  class ArchiveWorkflow < Gush::Workflow
    def configure(work_id=nil, file_set_id=nil)
      STDERR.puts "Here in workflow"
      run HyraxArchivematica::AssessForArchivingJob, params: {work_id: work_id, file_set_id: file_set_id}, queue: 'default'
      run HyraxArchivematica::CreateBagJob, after: HyraxArchivematica::AssessForArchivingJob, queue: 'default'
      run HyraxArchivematica::ScpBagJob, after: HyraxArchivematica::CreateBagJob, queue: 'default'

      run HyraxArchivematica::ArchivematicaTransferJob, after: HyraxArchivematica::ScpBagJob, queue: 'default'
#      run CheckTransferJob, after: ArchivematicaTransferJob

#      run ArchivematicaIngestJob, after: CheckTransferJob
#      run CheckIngestJob, after: ArchivematicaIngestJob

    end
  end
end
