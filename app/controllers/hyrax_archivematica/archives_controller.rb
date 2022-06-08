# frozen_string_literal: true

require_dependency "hyrax_archivematica/application_controller"

module HyraxArchivematica
  class ArchivesController < ApplicationController
    include Hyrax::ThemedLayoutController
    include HyraxArchivematica::ArchiveRecordBehaviour
    before_action :authenticate_user!
#    before_action :set_exporter, only: [:show, :edit, :update, :destroy]
    with_themed_layout 'dashboard'

    # Catch permission errors
    # TODO: Isn't this already handled?
    rescue_from CanCan::AccessDenied do |exception|
      if current_user&.persisted?
        redirect_to root_url, alert: exception.message
      else
        session["user_return_to"] = request.url
        redirect_to main_app.new_user_session_url, alert: exception.message
      end
    end

    def new
      HyraxArchivematica::ArchiveWorkflowManager.new(params: {user: current_user, work_id: params[:id], force: true})
      redirect_to hyrax_archivematica.work_archives_path, notice: "New archive process started"
    end

    def create
      @proxy_deposit_request.sending_user = current_user
      if @proxy_deposit_request.save
        redirect_to hyrax.archives_path, notice: "Archive job created"
      else
        @work = Hyrax::WorkRelation.new.find(params[:id])
        render :new
      end
    end

    def index
      @archive_records = archive_records(params[:id])
      @work = Hyrax::WorkRelation.new.find(params[:id])
      add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb @work.to_s, main_app.polymorphic_path(@work) 
      add_breadcrumb t(:'hyrax_archivematica.dashboard.work.archives'), hyrax_archivematica.work_archives_path
    end

    private

    def authorize_depositor_by_id
      @id = params[:id]
      authorize! :archive, @id
      @archive_record.work_id = @id
    rescue CanCan::AccessDenied
      redirect_to root_url, alert: 'You are not authorized to archive this work.'
    end

    def load_archive_record
      @archive_record = ArchiveRecord.new(archive_record_params)
    end

    def archive_record_params
      params.require(:id)
    end

  end
end
