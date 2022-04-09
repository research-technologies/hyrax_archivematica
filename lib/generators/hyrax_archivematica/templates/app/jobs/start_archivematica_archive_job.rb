# Converts UploadedFiles into FileSets and attaches them to works.
class StartArchivematicaArchiveJob < Hyrax::ApplicationJob

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, user)
    # work = work.parent if work.file_set?
    @work = work
    STDERR.puts "I have existing files they are #{work.file_sets}"
    write_files
    write_metadata
    build_bag
    build_zip
    cleanup
    # TODO bulkrax does not yet have a bagit exporter, but when it does we should check for it and use it rather than having to do our own
    
    
#    @uploaded_files = uploaded_files
#    validate_files!(uploaded_files)
#    @ordered_members = work.ordered_members.to_a # Build array of ordered members
#    depositor = proxy_or_depositor(work)
#    user = User.find_by_user_key(depositor)
#    metadata = visibility_attributes(work_attributes)
#    add_uploaded_files(user, metadata, work)
#    add_ordered_members(user, work)
  end

  private

    def build_bag
      WillowSword::BagPackage.new(bagit_work_path, transfer_work_path)
    end

    def build_zip
      # Maybe remove condition if we have problem with zips updating, but WS will error if it finds a zip file in place...
      WillowSword::ZipPackage.new(transfer_work_path, "#{transfer_work_path}.zip").create_zip unless File.exist?("#{transfer_work_path}.zip") 
    end

    def bagit_export_path
      HyraxArchivematica.bagit_export_path
    end

    def transfer_path
      HyraxArchivematica.transfer_path
    end

    def bagit_work_path
      File.join(bagit_export_path,@work.id.to_s)
    end

    def transfer_work_path
      File.join(transfer_path,@work.id.to_s)
    end

    def write_metadata
      return if @work.is_a?(Collection)
      write_json add_file_set_metadata_to_work_metadata
      write_dc_xml
    end

    def oai_dc_xml_url
      #/catalog/oai?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:hyrax:p8418n20k
      url = CatalogController.blacklight_config.oai[:provider][:repository_url]
      params = { identifier: "#{CatalogController.blacklight_config.oai[:provider][:record_prefix]}:#{@work.id}",
        verb: 'GetRecord',
        metadataPrefix: 'oai_dc' }
      "#{url}?#{params.to_query}"
    end

    def read_oai_dc_xml
      u = URI(oai_dc_xml_url)
      Net::HTTP.start(u.host, u.port, :use_ssl => u.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Get.new(u)
        response = http.request(request)
        response.read_body
      end
    end

    def write_dc_xml
      dc_xml = extract_dc_xml read_oai_dc_xml
      STDERR.puts dc_xml
      File.open(File.join(bagit_work_path, 'dc.xml'), "w:UTF-8") do |f|
          f.write(dc_xml)
      end
    end

    def extract_dc_xml(oai_dc_xml)
      doc = Nokogiri::XML(oai_dc_xml)
      doc.remove_namespaces!
      doc.xpath('//dc')
    end

    def write_json(json_data)
      # Without the line ending, there is a checksum mismatch when the bag is unzipped
      File.open(File.join(bagit_work_path, 'metadata.json'), "w:UTF-8") do |f|
        f.write "#{JSON.pretty_generate(json_data)}\n"
      end
    end

    def add_file_set_metadata_to_work_metadata
      work_hash = JSON.parse @work.to_json
      work_hash['file_sets'] = @work.file_sets.reject { |_, v| v.blank? }
      work_hash.reject { |_, v| v.blank? }
    end

    def write_files
      return if @work.is_a?(Collection)
      @work.file_sets.each do |fs|
        path = File.join(bagit_work_path, 'files')
        FileUtils.mkdir_p(path)
        file = filename(fs)
        require 'open-uri'
        io = open(fs.original_file.uri)
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
        return fn if mime.to_s == ext_mime.to_s
        return "#{fn}.#{mime.to_sym}"
      else
        return "#{file_set.id}_#{fn}" if mime.to_s == ext_mime.to_s
        return "#{file_set.id}_#{fn}.#{mime.to_sym}"
      end
    end
 
    def cleanup
      FileUtils.rm_r(bagit_work_path) if Dir.exist?(bagit_work_path)
      # Obvs we won't really remove the bagit zip file at this point!
      FileUtils.rm_r(transfer_work_path) if Dir.exist?(transfer_work_path)
#      FileUtils.rm("#{transfer_work_path}.zip") if File.exist?("#{transfer_work_path}.zip")
    end

end
