# frozen_string_literal: true

module Archivematica
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets and initiates process of archiving to archivematica
    class ArchivematicaListener
      ##
      # @param event [Dry::Event]
#      def on_object_metadata_updated(event)
#        # Don't trigger archive if file_set metadata is updated? 
#        # metadata is updated for _all_ file_sets when one is attached (so use attached to trigger)
#        return if event[:object].file_set?
#        # TODO check _essential_ metadata has changed... 
#        # How?
#        # We keep a checksum of the metadata values with the work/uuid AM object
#        # TODO avoid kicking off two procs if essential MD update AND file attach/delete happens
#        StartArchivematicaArchiveJob.perform_later(event[:object], event[:user])
#      end

      ##
      # @param event [Dry::Event]
      def on_file_set_attached(event)
        STDERR.puts "###### IN archivematica file_Set_attached.... "
        StartArchivematicaArchiveJob.perform_later(event[:file_set].parent, event[:user])
      end

#      def on_object_deleted(event)
#        # Only (re) archive if deletion is of a file_set i don't think we have the object here (what with it being deleted...
#        return unless event[:object].file_set?
#        StartArchivematicaArchiveJob.perform_later(event[:object].parent, event[:user])
#      end

    end
  end
end
