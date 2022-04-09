module HyraxArchivematica

  class << self
    # TODO: remove collection_field_mapping when releasing v2
    mattr_accessor :bagit_export_path,
                   :transfer_path

    self.bagit_export_path = 'tmp/bagit_export'
    self.transfer_path = 'tmp/am_transfer'
  end

  # this function maps the vars from your app into your engine
  def self.config(&block)
    yield self if block
  end

end
