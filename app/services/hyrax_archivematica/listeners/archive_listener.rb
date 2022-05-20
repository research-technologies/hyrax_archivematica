# frozen_string_literal: true
#require_dependency "hyrax_archivematica/app/workflows/archive_workflow"

module HyraxArchivematica
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets and initiates process of archiving to archivematica
    class ArchiveListener
 
      # on_metadata_updates languishes in an actor becuase we must access the new and old versions of the metadata

      # object.archive.prepared is our own and is triggered after _all_ files are attached
      def on_object_archive_prepared(event)
        #StartArchiveJob.perform_later(event[:object]) if Sidekiq.server? # we only want to listen to this pub if it is sidekiq that is publishing it
        #ArchiveWorkflow.new(event[:object])# we only want to listen to this pub if it is sidekiq that is publishing it
        if Sidekiq.server? 
          flow = HyraxArchivematica::ArchiveWorkflow.create(event[:object].id)
          flow.start!
        end
      end

      def on_object_deleted(event)
        # The following two attempts to get the work are almost certainly doomed to failure
        if event.payload.key?(:object)
          work = event[:object].parent 
        else
          work = ActiveFedora::Base.where("file_set_ids_ssim:#{event[:id]}")
        end
        # As far as I can see we are doomed never to have access to the work from which the file has been removed
        if work.empty?
           # We are very very likely to have no work, so all we can send is the file_set_id of the deleted file
           # with this we can start the job and that will check to see if there is an archive_record with the same 
           # file_set_id and from that it will get the work
           #
           # NB this will only work if the work has already been archived and there exists an ArchiveRecord with the fileset list
           #StartArchiveJob.perform_later(nil,event[:id]) 
#           ArchiveWorkflow.new(nil,event[:id])
          flow = HyraxArchivematica::ArchiveWorkflow.create(nil,event[:id])
          flow.start!
        else
           # Not sure we get here and if we do, not sure we really want to start an archive job
           # That would archive a work that has just been deleted... which defeats the object 
           # of an archive a wee bit
           # StartArchiveJob.perform_later(work) 
        end
      end

    end
  end
end
