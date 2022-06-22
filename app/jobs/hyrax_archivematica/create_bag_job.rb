# frozen_string_literal: true

module HyraxArchivematica
  # Assesses a work for readiness and changes before outputing 
  # NEW_AIP or UPDATE_AIP (or stops the workflow) accordingly
  class CreateBagJob < BaseJob
    include HyraxArchivematica::ArchiveRecordBehaviour

    def perform
 
      @user = User.where(email: params[:user][:id]).first
      prev_job_output = payloads.first[:output]
      @archive_record = ArchiveRecord.find(prev_job_output[:archive_record_id]) 
      @work = ActiveFedora::Base.find(@archive_record.work_id) 

      create_bag if prev_job_output[:new_aip]
      update_aip if prev_job_output[:update_aip]
  
      output({archive_record_id: @archive_record.id})

    rescue ActiveFedora::ObjectNotFoundError
      STDERR.puts "Could not find an archive record using the submitted params: #{prev_job_output}"
      # stop the workflow
      self.fail!
    end
  
    private
  
      def update_aip
        STDERR.puts "#################### Change to metadata only detected : attempt to update AIP ?? #################"
        STDERR.puts "#################### don't think a reingest will help as changed metadata is part of package, so new AIP required until I find out otherwise..."
        create_bag
      end

      def create_bag
        write_files
        write_metadata
        build_bag
        @bag_zip = build_zip
        @archive_record.update_attributes({bag_path: @bag_zip,
                                           bag_hash: calculate_bag_hash, 
                                           archive_status: HyraxArchivematica::Constants::STATUS_BAG_CREATED})
        cleanup_pre_bag_work_path
        cleanup_transfer_work_path
      end
  
      def write_files
        return if @work.is_a?(Collection)
        @work.file_sets.each do |fs|
          path = File.join(pre_bag_work_path, 'files')
          FileUtils.mkdir_p(path)
          file = filename(fs)
          require 'open-uri'
          io = URI.open(fs.original_file.uri)
          next if file.blank?
          File.open(File.join(path, file), 'wb') do |f|
            f.write(io.read)
            f.close
          end
        end
      end
  
      # Prepend the file_set id to ensure a unique filename
      def filename(file_set)
        return if file_set.original_file.blank?
        fn = file_set.original_file.file_name.first
        mime = Mime::Type.lookup(file_set.original_file.mime_type)
        ext_mime = MIME::Types.of(file_set.original_file.file_name).first
        if fn.include?(file_set.id)
          filename = "#{fn}.#{mime.to_sym}"
          filename = fn if mime.to_s == ext_mime.to_s
        else
          filename = "#{file_set.id}_#{fn}.#{mime.to_sym}"
          filename = "#{file_set.id}_#{fn}" if mime.to_s == ext_mime.to_s
        end
        # Remove extention truncate and reattach
        ext=File.extname(filename)
        "#{File.basename(filename,ext)[0...(255-ext.length)]}#{ext}"
      end

      def pre_bag_work_path
        File.join(bagit_export_path,@work.id.to_s)
      end
  
  
      def write_metadata
        return if @work.is_a?(Collection)
        write_json add_file_set_metadata_to_work_metadata
        write_dc_xml
      end
  
      def build_bag
        # TODO bulkrax does not yet have a bagit exporter, but when it does we should check for it and use it rather than having to do our own    
        FileUtils.mkdir_p(transfer_work_path(@work.id))
        WillowSword::BagPackage.new(pre_bag_work_path, transfer_work_path(@work.id))
      end
  
      def build_zip
        # Maybe remove condition if we have problem with zips updating, but WS will error if it finds a zip file in place...
        WillowSword::ZipPackage.new(transfer_work_path(@work.id), bag_zip_path).create_zip unless File.exist?(bag_zip_path) 
        bag_zip_path
      end

      def bag_zip_path
        @bag_zip_path ||= "#{transfer_work_path(@work.id)}_#{Time.now.to_i}.zip"
      end

      def calculate_bag_hash
        @bag_hash ||= calculate_md5 @bag_zip
      end
  
      def bagit_export_path
        HyraxArchivematica.bagit_export_path
      end
  
      def transfer_path
        HyraxArchivematica.transfer_path
      end
   
      def oai_dc_xml_url
        #/catalog/oai?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:hyrax:p8418n20k
        url = CatalogController.blacklight_config.oai[:provider][:repository_url]
        oai_params = { identifier: "#{CatalogController.blacklight_config.oai[:provider][:record_prefix]}:#{@work.id}",
          verb: 'GetRecord',
          metadataPrefix: 'oai_dc' }
        "#{url}?#{oai_params.to_query}"
      end
  
      def read_oai_dc_xml
        @current_ability = ::Ability.new(@user)
        presenter = Hyrax::PresenterFactory.build_for(ids: [@work.id], presenter_class: Hyrax::WorkShowPresenter, presenter_args: @current_ability).first
        presenter.solr_document.export_as_oai_dc_xml
      end
  
      def write_dc_xml
        @dc_xml = extract_dc_xml read_oai_dc_xml
        File.open(File.join(pre_bag_work_path, 'dc.xml'), "w:UTF-8") do |f|
            f.write "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{@dc_xml.to_s}\n"
        end
      end
  
      def extract_dc_xml(oai_dc_xml)
        doc = Nokogiri::XML(oai_dc_xml)
        doc.remove_namespaces!
        doc.xpath('//dc')
      end
  
      def write_json(json_data)
        # Without the line ending, there is a checksum mismatch when the bag is unzipped
        File.open(File.join(pre_bag_work_path, 'metadata.json'), "w:UTF-8") do |f|
          f.write "#{JSON.pretty_generate(json_data)}\n"
        end
      end
  
      def add_file_set_metadata_to_work_metadata
        work_hash = JSON.parse @work.to_json
        work_hash['file_sets'] = @work.file_sets.reject { |_, v| v.blank? }
        work_hash.reject { |_, v| v.blank? }
      end
    
      def cleanup_pre_bag_work_path
        FileUtils.rm_r(pre_bag_work_path) if Dir.exist?(pre_bag_work_path)
      end
  
      def cleanup_transfer_work_path
        FileUtils.rm_r(transfer_work_path(@work.id)) if Dir.exist?(transfer_work_path(@work.id))
      end
  
  end
end
