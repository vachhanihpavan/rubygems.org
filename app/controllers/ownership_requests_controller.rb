class OwnershipRequestsController < ApplicationController
  before_action :find_rubygem
  before_action :set_ownership_call, only: :create
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_signin, unless: :owner?, only: :close

  def create
    @ownership_request = @rubygem.ownership_requests.new(ownership_call: @ownership_call, user: current_user, note: params[:note])
    if @ownership_request.save
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: "Your ownership request is successfully submitted!"
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: @ownership_request.errors.full_messages.to_sentence
    end
  end

  def update
    @ownership_request = OwnershipRequest.find_by!(id: params[:id])
    if params[:status] == "close" && @ownership_request.can_close?(current_user)
      @ownership_request.closed!
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: "Ownership request is closed."
    elsif params[:status] == "approve" && @rubygem.owned_by?(current_user)
      @ownership_request.approve(current_user)
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: "Ownership request is approved."
    end
  end

  def close
    if @rubygem.ownership_requests.opened.update_all(status: :closed)
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: "All ownership requests are closed!"
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: t('try_again')
    end
  end

  private

  def set_ownership_call
    @ownership_call = @rubygem.ownership_call
  end

  def owner?
    @rubygem.owned_by?(current_user)
  end
end
