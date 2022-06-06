module HyraxArchivematica
  class Api
    # Interfaces to Archivematica and Archivematica Storage Service APIs
    # All have a request method that returns a Faraday::Response object

    # Base api module
    module ApiBase
      attr_reader :params

      RESPONSES = {
        'Faraday::ClientError' => 418,
        'Faraday::ConnectionFailed' => 598,
        'Faraday::ResourceNotFound' => 404,
        'Faraday::ParsingError' => 418,
        'Faraday::TimeoutError' => 598,
        'Faraday::SSLError' => 418,
        'Faraday::RetryableResponse' => 449, # RetryWith
        'RuntimeError' => 418
      }.freeze

      def initialize(params: {})
        @params = params
      end

      def response_for(error:)
        response = Faraday::Response.new(
          status: RESPONSES[error.class.to_s],
          body: nil
        )
        response.env.reason_phrase = error.message
        response
      end

      def connection_for(url:, auth:)
        Faraday.new(url: url) do |faraday|
          faraday.headers['Authorization'] = auth
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter do |client|
            client.read_timeout = 600
          end
        end
      end
    end

    # Creates connection to archivematica
    module ArchivematicaConnection
      def connection
        raise 'environment variables are not set' if HyraxArchivematica.am_host.blank? || HyraxArchivematica.am_user.blank? || HyraxArchivematica.am_api_key.blank?
        auth = "ApiKey #{HyraxArchivematica.am_user}:#{HyraxArchivematica.am_api_key}"
        connection_for(url: "#{HyraxArchivematica.am_protocol}://#{HyraxArchivematica.am_host}", auth: auth)
      end
    end

    # Creates connection to archivematica storage service
    module StorageServiceConnection
      def connection
        raise 'environment variables are not set' if HyraxArchivematica.am_host.blank? || HyraxArchivematica.am_storage_service_user.blank? || HyraxArchivematica.am_storage_service_api_key.blank?
        auth = "ApiKey #{HyraxArchivematica.am_storage_service_user}:#{HyraxArchivematica.am_storage_service_api_key}"
        connection_for(url: "#{HyraxArchivematica.am_protocol}://#{HyraxArchivematica.am_host}:#{HyraxArchivematica.am_storage_service_port}", auth: auth)
      end
    end

    # Interface for the start_transfer api call
    class StartTransfer
      include HyraxArchivematica::Api::ApiBase
      include ArchivematicaConnection
      # POST /api/transfer/start_transfer/
      # params must contain [:path]
      #   path is the transfer_source_path for the transfer in archivemaica
      # params may contain [:name], [:accession] and [:type]
      #   the default type is 'unzipped bag'
      #   other valid options are: standard, unzipped bag, dspace
      # @return [FaradayResponse] response
      def request
        raise 'path (a String) is required' if params[:path].blank?
        raise 'AM_TS environment variable is not set' if HyraxArchivematica.am_transfer_source_uuid.blank?
        type = params[:type] || 'unzipped bag'
        name = params[:name] || params[:path].split('/').last
        accession = params[:accession] || 'deposit via HyraxArchivematica::Api::StartTransfer '
        connection.post '/api/transfer/start_transfer/',
                        name: name,
                        type: type,
                        accession: accession,
                        paths: [Base64.encode64("#{HyraxArchivematica.am_transfer_source_uuid}:#{params[:path]}")]
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/approve api call
    class ApproveTransfer
      include HyraxArchivematica::Api::ApiBase
      include ArchivematicaConnection
      # POST /api/transfer/approve/
      # params must contain [:directory]
      #   directory is the transfer directory name, not the full path
      # params may contain [:type]
      #   the default type is 'zipped bag'
      #   other valid options are: standard, unzipped bag, dspace
      # @return [FaradayResponse] response
      def request
        raise 'directory is required' if params[:directory].blank?
        type = params[:type] || 'unzipped bag'

        connection.post '/api/transfer/approve',
                        directory: params[:directory],
                        type: type
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/unapproved api call
    class UnapprovedTransfers
      include HyraxArchivematica::Api::ApiBase
      include ArchivematicaConnection
      # GET /api/transfer/unapproved
      # @return [FaradayResponse] response
      def request
        connection.get '/api/transfer/unapproved'
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/status api call
    class TransferStatus
      include HyraxArchivematica::Api::ApiBase
      include ArchivematicaConnection
      # GET /transfer/status/<UUID>/
      # params must contain [:uuid] - transfer uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/transfer/status/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the ingest/status api call
    class IngestStatus
      include HyraxArchivematica::Api::ApiBase
      include ArchivematicaConnection
      # GET /ingest/status/<UUID>/
      # params must contain [:uuid] - sip/aip uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/ingest/status/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the package details api call
    class PackageDetails
      include HyraxArchivematica::Api::ApiBase
      include StorageServiceConnection
      # GET /api/v2/file/<UUID>/
      # @param uuid [String] sip/aip uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/v2/file/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end

      # Extract any DIP UUIDs from the AIP details (or vice versa)
      # @param related_packages [Hash]
      # @return [Array] dip uuids
      def dip_uuids(related_packages)
        return [] if related_packages.blank?
        related_packages.collect { |pack| pack.split('/').last }
      end
    end
  end
end
