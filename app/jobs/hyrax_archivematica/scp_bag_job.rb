# frozen_string_literal: true
require 'net/ssh'
require 'net/scp'
#require_dependency "hyrax_archivematica/app/jobs/hyrax_archivematica_job_behaviour"

module HyraxArchivematica
  # Converts UploadedFiles into FileSets and attaches them to works.
  class ScpBagJob < Gush::Job
    include HyraxArchivematica::HyraxArchivematicaJobBehaviour

    def perform
      prev_job_output = payloads.first[:output]
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id]) 
      transfer_bag
      if verify_transfer
        @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_TRANSFER_VERIFIED})
        output({archive_record_id: @archive_record.id})
      else
        @archive_record.update_attributes({archive_status: HyraxArchivematica::Constants::STATUS_TRANSFER_NOT_VERIFIED})       
        self.fail!
      end
    end

    def bag_path
      @archive_record.bag_path
    end

    def bag_zip
      File.basename(bag_path)
    end

    def bag_hash
      @archive_record.bag_hash
    end

    def ssh_private_keys
      [am_ssh_key]
    end
    
    def transfer_bag
      Net::SSH.start(am_host, am_ssh_user, key_data: ssh_private_keys, keys_only: true) do |ssh|
        ssh.scp.upload!(bag_path, am_transfer_source_dir)
      end
    end
    
    def verify_transfer
      Net::SSH.start(am_host, am_ssh_user, key_data: ssh_private_keys, keys_only: true) do |ssh|
        # So running something on a remote host eh? difficult to capture errors like md5sum not being available
        # or the file not being where we expect. So we hide the errors and if we don't get anything we assume 
        # that something vague has gone wrong with verification
        remote_bag_hash = ssh.exec!("md5sum #{am_transfer_source_dir}/#{bag_zip} 2> /dev/null | awk '{print $1}'").chomp
        if remote_bag_hash.blank?
          STDERR.puts "############# could not verify the transferred file due to some issue on the host"
          return false
        end
        STDERR.puts "############# *#{remote_bag_hash}*  <=====> *#{bag_hash}*"
        remote_bag_hash.eql? bag_hash
      end
    end


  end
end
