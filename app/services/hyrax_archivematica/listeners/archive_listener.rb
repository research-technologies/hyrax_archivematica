# frozen_string_literal: true
require_dependency "hyrax_archivematica/app/jobs/start_archive_job"

module HyraxArchivematica
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets and initiates process of archiving to archivematica
    class ArchiveListener
 
      # @param event [Dry::Event]
      def on_object_metadata_updated(event)
        # Don't trigger archive if file_set metadata is updated? 
        # metadata is updated for _all_ file_sets when one is attached (so use attached to trigger)
        return if event[:object].file_set?
        # TODO filter out collections and other objects that might publish
        STDERR.puts "############ OBJECT_METADATA_UPDATED (work)"

        # SO what we need todo is to shift this (back) to the actor stack... and there we can access the uploaded_files attribute to check for change... 
        # if there is change then quit because file attach should catch the change when done
        # if there is no change then we _could_ have an update to significant metadata only so start the archivematicaJob from there

#        StartArchiveJob.perform_later(event[:object], event[:user])

      end

      def on_object_archive_prepared(event)
        STDERR.puts "############# OBJECT_ARCHIVE_PREPARED: #{event[:object]}"
        StartArchiveJob.perform_later(event[:object]) if Sidekiq.server?
      end

      def on_object_deposited(event)
        # I think this is triggered when a new object (work) is created
        # Don't think we need to act on this as metadata_updated likely 
        # to be triggered for new and update
        return if event[:object].file_set?
        STDERR.puts "############# OBJECT_DEPOSITED"
#        StartArchiveJob.perform_later(event[:object], event[:user])
      end

      ##
      # @param event [Dry::Event]
      def on_file_set_attached(event)
        STDERR.puts "################ FILE_ATTACHED"
         # file set attachement event appears to be repeated a lot so can't really trust this to be sarting jobs with
#        StartArchiveJob.perform_later(event[:file_set].parent, event[:user])
      end

      def on_object_deleted(event)
        # The following two attempts to get the work are almost certainly doomed to failure
        if event.payload.key?(:object)
          work = event[:object].parent 
        else
          work = ActiveFedora::Base.where("file_set_ids_ssim:#{event[:id]}")
        end
        STDERR.puts "############ OBJECT_DELETED (file)"
        if work.empty?
           # We are very very likely to have no work, so all we can send is the file_set_id of the deleted file
           # with this we can start the job and that will check to see if there is an archive_record with the same 
           # file_set_id and from that it will get the work
           StartArchiveJob.perform_later(nil,event[:id]) 
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
