module HyraxArchivematica

  class << self
    # TODO: remove collection_field_mapping when releasing v2
    mattr_accessor :bagit_export_path, :transfer_path, 
                   :significant_metadata, :am_ssh_key, 
                   :am_host, :am_user, :am_protocol, 
                   :am_storage_service_port, :am_api_key,
                   :am_transfer_source_uuid, :am_storage_service_api_key ,
                   :am_transfer_source_dir

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

end
