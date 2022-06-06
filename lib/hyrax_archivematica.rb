require 'active_support/all'

module HyraxArchivematica

  class << self
    # TODO: remove collection_field_mapping when releasing v2
    mattr_accessor :bagit_export_path, :transfer_path, 
                   :significant_metadata, :am_ssh_key, :am_ssh_user, 
                   :am_host, :am_user, :am_protocol, 
                   :am_storage_service_port, :am_api_key,
                   :am_transfer_source_uuid, :am_storage_service_api_key ,
                   :am_storage_service_user, :am_transfer_source_dir

#  config.am_ssh_key = File.read('/home/ec2-user/.ssh/azure_id_rsa') # docker/stax_archivematica
#  config.am_host = 'archivematica-uat.hull.cdl.cosector.com' # stax-archive.lib.strath.ac.uk
#  config.am_user = 'azureuser' #archivematica #one user for ssh and AM api transactions? in this case but not guaranteed...
#
#  config.am_protocol = 'https'
#  config.am_storage_service_port = 8000
#  config.am_api_key = ''
#  config.am_transfer_source_uuid = ''
#  config.am_storage_service_api_key = ''


    self.bagit_export_path = 'tmp/bagit_export'
    self.transfer_path = 'tmp/am_transfer'
    self.significant_metadata = %i[ title creator ]

  end

  # this function maps the vars from your app into your engine
  def self.config(&block)
    yield self if block
  end


  module Constants
    # Status constants
    STATUS_ARCHIVE_INITIALISED = 'archive_initialised'.freeze
    STATUS_BAG_CREATED = 'bag_created'.freeze
    STATUS_TRANSFER_VERIFIED = 'transferred_to_transfer_source'.freeze
    STATUS_TRANSFER_NOT_VERIFIED = 'transfer_to_transfer_source_failed'.freeze
    STATUS_AM_TRANSFER_STARTED = 'am_transfer_started'.freeze
    STATUS_AM_TRANSFER_IN_PROGRESS = 'am_transfer_in_progress'.freeze
    STATUS_AM_TRANSFER_WAITING = 'am_transfer_waiting'.freeze
    STATUS_AM_TRANSFER_FAILED = 'am_transfer_failed'.freeze
    STATUS_AM_TRANSFER_SUCCESS = 'am_transfer_succeeded'.freeze
    STATUS_AM_APPROVAL_SUCCESS = 'am_approval_succeeded'.freeze
    STATUS_AM_APPROVAL_FAILED = 'am_approval_failed'.freeze
    STATUS_AM_INGEST_STARTED = 'am_ingest_started'.freeze
    STATUS_AM_INGEST_IN_PROGRESS = 'am_ingest_in_progress'.freeze
    STATUS_AM_INGEST_WAITING = 'am_ingest_waiting'.freeze
    STATUS_AM_INGEST_FAILED = 'am_ingest_failed'.freeze
    STATUS_AM_INGEST_SUCCESS = 'am_ingest_succeeded'.freeze
    STATUS_ARCHIVE_COMPLETE = 'archive_complete'.freeze
    STATUS_ERROR = 'error'.freeze # catchall error status
  end


end

# Require our engine
require "hyrax_archivematica/engine"
