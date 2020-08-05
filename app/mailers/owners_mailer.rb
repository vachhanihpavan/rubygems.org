class OwnersMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  include OwnersHelper
  helper :owners

  default from: Clearance.configuration.mailer_sender

  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def ownership_confirmation(ownership_id)
    @ownership = Ownership.find(ownership_id)
    @user = @ownership.user
    @rubygem = @ownership.rubygem
    mail to: @user.email,
         subject: t("mailer.ownership_confirmation.subject", gem: @rubygem.name,
                         default: "Please confirm the ownership of %{gem} gem on RubyGems.org")
  end

  def owner_removed(user_id, authorizer_id, gem_id)
    @user = User.find(user_id)
    @authorizer = User.find(authorizer_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: t("mailer.owner_removed.subject", gem: @rubygem.name)
  end

  def owner_added(owner_id, user_id, authorizer_id, gem_id)
    @user = User.find(user_id)
    @owner = User.find(owner_id)
    @authorizer = User.find(authorizer_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: t("mailer.owner_added.subject_#{owner_i18n_key(@owner, @user)}", gem: @rubygem.name, owner_handle: @owner.display_handle)
  end

  def new_ownership_requests(rubygem_id)
    @rubygem = Rubygem.find(rubygem_id)
    @ownership_requests_count = @rubygem.ownership_requests.opened.count
    @rubygem.owners.each do |owner|
      mail to: owner.email,
           subject: "New ownership request(s) for #{@rubygem.name}"
    end
  end

  def ownership_request_submitted(ownership_request_id)
    @ownership_request = OwnershipRequest.find(ownership_request_id)
    @rubygem = @ownership_request.rubygem
    @user = @ownership_request.user
    mail to: @user.email,
         subject: "Your ownership request was successfully submitted."
  end

  def ownership_request_approved(ownership_request_id)
    @ownership_request = OwnershipRequest.find(ownership_request_id)
    @rubygem = @ownership_request.rubygem
    @user = @ownership_request.user
    mail to: @user.email,
         subject: "Your ownership request was approved."
  end

  def ownership_request_closed(ownership_request_id)
    @ownership_request = OwnershipRequest.find(ownership_request_id)
    @rubygem = @ownership_request.rubygem
    @user = @ownership_request.user
    mail to: @user.email,
         subject: "Your ownership request was closed."
  end
end
