# frozen_string_literal: true

HyraxArchivematica.config do |config|

  #TODO read env for these
  config.bagit_export_path = 'tmp/pre_bags'
  config.transfer_path = 'tmp/am_transfer_bags'

  config.am_host = 'archivematica.example.com' # archivematica host
 config.am_protocol = 'https'

  config.am_ssh_key = # ssh key to allow ssh of bags to archivematica host maybe : File.read('/path/to/my/ssh_key_archivematica_host') 
  config.am_ssh_user = '' # username for user for ssh

  config.am_user = '' # username for user for AM api transactions
  config.am_transfer_source_dir = '/var/tmp/' #:

  config.am_storage_service_port = 8000
  # Available from archivemarica dashboard user API_KEY on user account edit page 
  config.am_api_key = ''
  # Archivematica Transfer source UUID available {am_protocol}://{am_host}:{am_storage_service_port}/locations/
  config.am_transfer_source_uuid = ''
  config.am_storage_service_api_key = ''

  config.significant_metadata = %i[
    title
    creator
  ]
end

require 'hyrax_archivematica/app/services/hyrax_archivematica/listeners/archive_listener'
# register our listener
Hyrax.publisher.subscribe(HyraxArchivematica::Listeners::ArchiveListener.new)

# Respond to "special" callback by publishing the message that _all_ files have been attached
Hyrax.config.callback.set(:after_attach_filesets, warn: false) do |work, user|
  Hyrax.publisher.publish('object.archive.prepared', object: work, user: user)
end


# Above works nicely when attaching and removing files, for changes to _only_ significant metadata we need to get in to the actor
# Reason for this is that we need to be able to compare the current files and the uploaded files to see that there has been no 
# change, if there has not we will not expect that the Start AM job will be subsequently started by the above and we acn asses
# whether the metadata change trigger the significant metadata conditions for an AIP update
# We insert BEFORE the CreateWithFilesActor (in this case swapped with CreateWithFilesOrderedMembersActor) has deleted the uploaded files

require 'hyrax_archivematica/app/actors/hyrax/actors/hyrax_archivematica_actor'
Hyrax.config do | config |
  Hyrax::CurationConcern.actor_factory.insert_before Hyrax::Actors::CreateWithFilesActor, Hyrax::Actors::HyraxArchivematicaActor
end

# Monkey patch the ordered member actor to publish a message when _all_ the files have been attached
# If you look above you'll see where we subscribe to that message
# Overrides Hyrax v3.3.0
Hyrax::Actors::OrderedMembersActor.class_eval do
  def attach_ordered_members_to_work(work)
    acquire_lock_for(work.id) do
      work.ordered_members = ordered_members
      work.save
      ordered_members.each do |file_set|
        Hyrax.config.callback.run(:after_create_fileset, file_set, user, warn: false)
      end
    end
    # Run this call back so that we can publish the message that _all_ filesets have been attached
    Hyrax.config.callback.run(:after_attach_filesets, work, user, warn: false)
  end
end
