# frozen_string_literal: true
require_dependency "hyrax_archivematica/app/jobs/start_archive_job"

module Hyrax
  module Actors
    class HyraxArchivematicaActor < Hyrax::Actors::BaseActor

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        # If uploaded_files is empty we assume this is a metadata only create and no file attach or delete messages will be published
        # So we will trigger archiving here and things like significant changes and whether to go ahead can be checked by the job
        StartArchiveJob.perform_later(env.curation_concern) if env.attributes[:uploaded_files].empty?
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        # If uploaded_files is empty we assume this is a metadata only update and no file attach or delete messages will be published
        # So we will trigger archiving here and things like significant changes and whether to go ahead can be checked by the job
        StartArchiveJob.perform_later(env.curation_concern) if env.attributes[:uploaded_files].empty?
        next_actor.update(env)
      end

    end
  end
end
