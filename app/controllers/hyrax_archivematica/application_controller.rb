# frozen_string_literal: true

module HyraxArchivematica
  class ApplicationController < ::ApplicationController
    helper Rails.application.class.helpers
    protect_from_forgery with: :exception
  end
end
