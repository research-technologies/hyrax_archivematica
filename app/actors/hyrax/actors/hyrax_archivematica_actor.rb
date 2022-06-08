# frozen_string_literal: true
#require_dependency "hyrax_archivematica/app/workflows/archive_workflow"

module Hyrax
  module Actors
    class HyraxArchivematicaActor < Hyrax::Actors::BaseActor

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        # If uploaded_files is empty we assume this is a metadata only create and no file attach or delete messages will be published
        # So we will trigger archiving here and things like significant changes and whether to go ahead can be checked by the job
        if env.attributes[:uploaded_files].empty? 
          HyraxArchivematica::ArchiveWorkflowManager.new(params: {user: env.user, work_id: env.curation_concern.id})
        end
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        # If uploaded_files is empty we assume this is a metadata only update and no file attach or delete messages will be published
        # So we will trigger archiving here and things like significant changes and whether to go ahead can be checked by the job
        if env.attributes[:uploaded_files].empty?
          HyraxArchivematica::ArchiveWorkflowManager.new(params: {user: env.user, work_id: env.curation_concern.id})
        end
        next_actor.update(env)
      end

    end
  end
end
