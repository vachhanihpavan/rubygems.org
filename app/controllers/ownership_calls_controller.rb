class OwnershipCallsController < ApplicationController
  before_action :set_page, only: :index
  before_action :find_rubygem, except: :index
  before_action :redirect_to_signin, unless: :owner?, only: %i[create update]
  before_action :redirect_to_signin, unless: :signed_in?, only: :show

  def index
    @ownership_calls = OwnershipCall.opened.order(created_at: :desc).page(@page)
  end

  def show
    @ownership_call = @rubygem.ownership_call
    @ownership_requests = @rubygem.ownership_requests.opened
    @user_request = if @ownership_call
                      @ownership_call.ownership_requests.opened.find_by(user: current_user)
                    else
                      @rubygem.ownership_requests.opened.find_by(user: current_user, ownership_call: nil)
                    end
  end

  def create
    @ownership_call = @rubygem.ownership_calls.new(user: current_user, note: params[:note],
                                 email: params[:email])
    if @ownership_call.save
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: "Ownership call opened successfully!"
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: @ownership_call.errors.full_messages.to_sentence
    end
  end

  def update
    @ownership_call = @rubygem.ownership_call
    if @ownership_call.close
      redirect_to rubygem_path(@rubygem), notice: "Ownership call was successfully closed."
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: t("try_again")
    end
  end

  private

  def owner?
    @rubygem.owned_by?(current_user)
  end
end
