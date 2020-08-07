require "test_helper"

class OwnershipRequestsTest < SystemTest
  include ActionMailer::TestHelper

  setup do
    @owner = create(:user)
  end

  test "create ownership request" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    visit ownership_calls_path(as: user.id)
    click_link "Apply"

    fill_in "Note", with: "request has _italics_ with *bold*."
    click_button "Apply"
    assert_selector :css, "div.gems__gem__info > p", text: "request has italics with bold."
    assert page.has_button? "Close"
    refute page.has_button? "Approve"
  end

  test "approve ownership request by owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit rubygem_ownership_calls_path(rubygem, as: @owner.id)

    click_button "Approve"

    Delayed::Worker.new.work_off
    assert_emails 3
    assert rubygem.owners.include?(user)
  end

  test "close ownership request by requester" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit rubygem_ownership_calls_url(rubygem, as: user.id)

    click_button "Close"
    assert_empty rubygem.ownership_requests
    Delayed::Worker.new.work_off
    assert_no_emails
  end

  test "close ownership request by owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create(:ownership_call, rubygem: rubygem)
    create(:ownership_request, user: user, rubygem: rubygem)

    visit rubygem_ownership_calls_path(rubygem, as: @owner.id)

    page.find("#owner_close_request").click

    assert_empty rubygem.ownership_requests
    Delayed::Worker.new.work_off
    assert_emails 1
    assert_equal "Your ownership request was closed.", last_email.subject
  end

  test "cannot close all requests as user" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    create_list(:ownership_request, 3, rubygem: rubygem)

    visit rubygem_ownership_calls_path(rubygem, as: user.id)

    refute page.has_link? "Close All"
  end

  test "close all requests as owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    create_list(:ownership_request, 3, rubygem: rubygem)

    visit rubygem_ownership_calls_path(rubygem, as: @owner.id)

    assert page.has_link? "Close All"
    click_link "Close All"
    Delayed::Worker.new.work_off
    assert_emails 3
  end
end
