# frozen_string_literal: true

module HyraxArchivematica
  # Assesses a work for readiness and changes before outputing 
  # NEW_AIP or UPDATE_AIP (or stops the workflow) accordingly
  class AssessForArchivingJob < BaseJob
    include HyraxArchivematica::ArchiveRecordBehaviour
  
    # @param [String] work_id - the work id
    # @param [String] file_set_id - the ile_set_ids
    def perform
      work = ActiveFedora::Base.find(params[:work_id]) unless params[:work_id].blank?
      force = params[:force] || false
      # If we are triggered by a file_set removal, we have nothing but the file_set_id to go on
      # We use this (and hope) that theres an archive_record and get the parent work if from that (!?)
      if work.nil? && params[:file_set_id].present?
         ar = latest_archive_record_by_file_set_id params[:file_set_id]
         work = ActiveFedora::Base.find(ar.work_id) unless ar.nil?
      end
      
      raise ActiveFedora::ObjectNotFoundError if work.blank?

      # Some instance variables
      @work = work 
      raise ActiveFedora::ObjectNotFoundError if @work.file_sets.empty? # Refuse to archive work which has no files"

      #####################
      # TODO we need to compare the new archive record with the previous one... not the new (in only) OR last archive record with whatever is now !?
      #####################
      # Get the latest existing AR
      @prev_archive_record = archive_records(@work.id)&.first
      # Find the latest NOT COMPLETE AR, if there is not one we will create a new empty AR
      @archive_record = active_archive_records(@work.id).first_or_create # Create an AR if there is not already an active one
      # If there was no previous AR, we will make the new one the previous one this will allow us to compare the current state against something (albeit a mostly empty AR)
      @prev_archive_record = @archive_record if @prev_archive_record.blank? 

      if files_change? || force
        output({new_aip: true, update_aip: false, archive_record_id: @archive_record.id})
      elsif metadata_change? && ! files_change? #metadata only change
        output({new_aip: false, update_aip: true, archive_record_id: @archive_record.id})
      else #no significant change, stop the workflow... should we destroy the ArchiveRecord here too?
        @archive_record.destroy!
        self.fail!
        return 
      end
  
      @archive_record.update_attributes({file_set_ids: @work.file_set_ids, 
                                     archive_status: HyraxArchivematica::Constants::STATUS_ARCHIVE_INITIALISED,
                                     metadata_hash: metadata_hash,
                                     files_hash: files_hash
                                   })

    rescue ActiveFedora::ObjectNotFoundError
      STDERR.puts "Could not find a work using the submitted ids or the work that was found has no files: #{params}"
      # stop the workflow
      self.fail!
    end
  
  
    private
   
      def files_hash
        # stick all the checksums (FileSet.original_checksum) of all the files together and generat an md5sum that
        # TODO will the checksum be avialable here for new files or must we calculate ourselves or wait until after characterization job is done :/
        return nil if @work.file_sets.empty?
        @files_hash ||= Digest::MD5.hexdigest(@work.file_sets.map{|fs| fs.original_checksum.first}.join(":")) 
      end
  
      def metadata_hash
        # Calculate md5sum of the json that represents all the significant metadata
        @metadata_hash ||= Digest::MD5.hexdigest(significant_metadata.to_json)
      end
      
      def significant_metadata
        @work.attributes.select{ |k,v| HyraxArchivematica.significant_metadata.include?(k.to_sym) }
      end
  
      def metadata_change?
        @prev_archive_record.metadata_hash != metadata_hash
      end
  
      def files_change?
        @prev_archive_record.files_hash != files_hash
      end
  
  end
end
