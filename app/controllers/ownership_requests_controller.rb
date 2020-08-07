class OwnershipRequestsController < ApplicationController
  before_action :find_rubygem
  before_action :set_ownership_call, only: :create
  before_action :redirect_to_signin, unless: :signed_in?

  def create
    render_forbidden && return if owner? || !can_request_ownership?
    @ownership_request = @rubygem.ownership_requests.new(ownership_call: @ownership_call, user: current_user, note: params[:note])
    if @ownership_request.save
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: t("ownership_requests.create.success_notice")
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: @ownership_request.errors.full_messages.to_sentence
    end
  end

  def update
    @ownership_request = OwnershipRequest.find_by!(id: params[:id])
    if params[:status] == "close" && @ownership_request.close(current_user)
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: t("ownership_requests.update.closed_notice")
    elsif params[:status] == "approve" && @ownership_request.approve(current_user)
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: t("ownership_requests.update.approved_notice", name: current_user.display_id)
    else
      render_not_found
    end
  end

  def close
    render_forbidden && return unless owner?
    if @rubygem.ownership_requests.close_all
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: t("ownership_requests.close.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: t("try_again")
    end
  end

  private

  def set_ownership_call
    @ownership_call = @rubygem.ownership_call
  end
end
