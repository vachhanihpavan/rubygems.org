class OwnershipCallsController < ApplicationController
  before_action :set_page, only: :index
  before_action :find_rubygem, except: :index
  before_action :render_not_found, unless: :can_request_ownership?, only: :show
  before_action :redirect_to_signin, unless: :signed_in?, except: :index
  before_action :render_forbidden, unless: :owner?, only: %i[create update]
  before_action :set_ownership_call, only: %i[show update]

  def index
    @ownership_calls = OwnershipCall.opened.includes(:user, rubygem: [:latest_version, :gem_download]).order(created_at: :desc)
      .page(@page)
      .per(Gemcutter::OWNERSHIP_CALLS_PER_PAGE)
  end

  def show
    @ownership_requests = @rubygem.ownership_requests.includes(:user)
    @user_request = @rubygem.ownership_requests.find_by(user: current_user)
  end

  def create
    @ownership_call = @rubygem.ownership_calls.new(user: current_user, note: params[:note])
    if @ownership_call.save
      redirect_to rubygem_ownership_calls_path(@rubygem), notice: t("ownership_calls.create.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: @ownership_call.errors.full_messages.to_sentence
    end
  end

  def update
    render_not_found && return unless @ownership_call

    if @ownership_call.close
      redirect_to rubygem_path(@rubygem), notice: t("ownership_calls.update.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_ownership_calls_path(@rubygem), alert: t("try_again")
    end
  end

  private

  def set_ownership_call
    @ownership_call = @rubygem.ownership_call
  end
end
