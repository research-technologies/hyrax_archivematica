# Converts UploadedFiles into FileSets and attaches them to works.
class StartArchivematicaArchiveJob < Hyrax::ApplicationJob

  before_enqueue do |job|
    @job_id = job.job_id
  end

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work=nil, file_set_id=nil)

    return if work.nil? && file_set_id.nil?

    # If we are triggered by a file_set removal, we have nothing but the file_set_id to go on
    # We use this (and hope) that theres an archive_record and get the parent work if from that (!?)
    if work.nil?
       ar = latest_archive_record_by_file_set_id file_set_id
       return if ar.nil?
       work = ActiveFedora::Base.find(ar.work_id)
    end

    STDERR.puts "#################################################"
    STDERR.puts "#### THE ARCHIVEMATICA JOB HAS BEEN STARTED #####"
    STDERR.puts "#################################################"

    @work = work
    if @work.file_sets.empty?
       STDERR.puts "Refusing to archive a work with no files"
       return
    end

    @archive_record = latest_archive_records.first_or_create


    if files_change? 
      @new_aip=true
    elsif metadata_change? && ! files_change? #metadata only change
      @update_aip=true
    else #no significant change
      STDERR.puts "########  Destroying AR"
      @archive_record.destroy && return 
    end

    update_archive_record HyraxArchivematica::ArchiveRecord::STATUS_ARCHIVE_INITIALISED

    new_aip if @new_aip
    update_aip if @update_aip

     # Not needed can remove along with job_id in AR model
#    if @archive_record.archive_status == HyraxArchivematica::ArchiveRecord::STATUS_ARCHIVE_INITIALISED
#      STDERR.puts "################## Archive Record is in init state already assuming this is a bounce??: #{@archive_record.archive_status}"
#      return
#    end

#      if @archive_record.archive_status == HyraxArchivematica::ArchiveRecord::STATUS_ARCHIVE_INITIALISED && @archive_record.job_id != @job_id
#        STDERR.puts "We jave another job running in parallel that is still in init state... kill them, and steal their boots!!"
#        Sidekiq::Status.delete(@archive_record.job_id)
#        @archive_record.job_id = @job_id
#      end

 
    STDERR.puts "ARchiVE RECORD: #{@archive_record}"
    
  end

  def latest_archive_records # Could become unwieldy
    HyraxArchivematica::ArchiveRecord.where(work_id:@work.id).order(created_at: :desc)
  end

  private


    def latest_archive_record_by_file_set_id(file_set_id)
      HyraxArchivematica::ArchiveRecord.all.order(created_at: :desc).select { |ar| ar.file_set_ids.include? file_set_id }.first
#      HyraxArchivematica::ArchiveRecord.where(file_set_ids:file_set_id).order(created_at: :desc).first
    end

    def files_hash
      # check md5sum of each file_set
      # TODO will the checksum be avialable here for new files or must we calculate ourselves or wiat until after characterization job is done :/
      return nil if @work.file_sets.empty?
      @files_hash ||= Digest::MD5.hexdigest(@work.file_sets.map{|fs| fs.original_checksum.first}.join(":")) 
    end

    def metadata_hash
      #calculate md5sum of each file in file_set and then caulculate md5sum of result
      @metadata_hash ||= Digest::MD5.hexdigest(significant_metadata.to_json)
    end
    
    def significant_metadata
      @work.attributes.select{ |k,v| HyraxArchivematica.significant_metadata.include?(k.to_sym) }
    end

    def metadata_change?
      @archive_record.metadata_hash != metadata_hash
    end

    def files_change?
      @archive_record.files_hash != files_hash
    end

    def update_archive_record(status)
       @archive_record.update_attributes({file_set_ids: @work.file_set_ids, 
                                   archive_status: status,
                                   metadata_hash: metadata_hash,
                                   files_hash: files_hash
                                 })
    end

    def new_aip
      STDERR.puts "#################### Change to file detected (maybe metadata too) : new AIP will be created #################"
      write_files
      write_metadata
      build_bag
      @bag_zip = build_zip
      cleanup_pre_bag_work_path
      cleanup_transfer_work_path
      start_transfer
    end

    def start_transfer
      STDERR.puts "#################### I will now transfer: #{@bag_zip} to #{am_user}@#{am_host}:#{am_transfer_source_dir}"
      send_bag_zip_to_am_host  
    end

    def update_aip
      STDERR.puts "#################### Change to (significant) metadata only detected : existing AIP will be updated #################"
    end

    def build_bag
      # TODO bulkrax does not yet have a bagit exporter, but when it does we should check for it and use it rather than having to do our own    
      WillowSword::BagPackage.new(pre_bag_work_path, transfer_work_path)
    end

    def build_zip
      # Maybe remove condition if we have problem with zips updating, but WS will error if it finds a zip file in place...
      WillowSword::ZipPackage.new(transfer_work_path, bag_zip_path).create_zip unless File.exist?(bag_zip_path) 
      bag_zip_path
    end

    def bagit_export_path
      HyraxArchivematica.bagit_export_path
    end

    def transfer_path
      HyraxArchivematica.transfer_path
    end

    def am_host
      HyraxArchivematica.am_host
    end

    def am_user
      HyraxArchivematica.am_user
    end

    def am_ssh_key
      HyraxArchivematica.am_ssh_key
    end

    def am_transfer_source_dir
      HyraxArchivematica.am_transfer_source_dir
    end

    def send_bag_zip_to_am_host
      require 'net/ssh'
      require 'net/scp'
      ssh_private_keys = [am_ssh_key]
      Net::SSH.start(am_host, am_user, key_data: ssh_private_keys, keys_only: true) do |ssh|
        ssh.scp.upload!(@bag_zip, am_transfer_source_dir)
      end
    end

    def pre_bag_work_path
      File.join(bagit_export_path,@work.id.to_s)
    end

    def transfer_work_path
      File.join(transfer_path,@work.id.to_s)
    end

    def bag_zip_path
      @bag_zip_path ||= "#{transfer_work_path}_#{Time.now.to_i}.zip"
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
      @dc_xml = extract_dc_xml read_oai_dc_xml
      File.open(File.join(pre_bag_work_path, 'dc.xml'), "w:UTF-8") do |f|
          f.write(@dc_xml)
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

    def write_files
      return if @work.is_a?(Collection)
      @work.file_sets.each do |fs|
        path = File.join(pre_bag_work_path, 'files')
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
 
    def cleanup_pre_bag_work_path
      FileUtils.rm_r(pre_bag_work_path) if Dir.exist?(pre_bag_work_path)
    end

    def cleanup_transfer_work_path
      # Obvs we won't really remove the bagit zip file at this point!
      FileUtils.rm_r(transfer_work_path) if Dir.exist?(transfer_work_path)
    end

    def cleanup_transfer_zip
      FileUtils.rm("#{transfer_work_path}.zip") if File.exist?("#{transfer_work_path}.zip")
    end
end
