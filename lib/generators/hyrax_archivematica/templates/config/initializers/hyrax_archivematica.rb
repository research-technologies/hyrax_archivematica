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
  # Archviematica Transfer source UUID available {am_protocol}://{am_host}:{am_storage_service_port}/locations/
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
