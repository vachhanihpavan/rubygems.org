require "test_helper"

class OwnershipCallTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem)
  end

  should belong_to :rubygem
  should have_db_index :rubygem_id
  should belong_to :user
  should have_db_index :user_id

  context "factory" do
    should "be valid with plain factory" do
      assert build(:ownership_call, user: @user, rubygem: @rubygem).valid?
    end

    should "be valid with closed trait" do
      ownership_call = build(:ownership_call, :closed, user: @user, rubygem: @rubygem)
      assert ownership_call.valid?
      assert ownership_call.closed?
    end
  end

  context "#create" do
    should "create a call with open status" do
      ownership_call = @rubygem.ownership_calls.create(user: @user, email: "test@example.com", note: "valid note")
      assert ownership_call.opened?
    end

    should "not create a call with note longer than 255 chars" do
      ownership_call = build(:ownership_call, user: @user, rubygem: @rubygem,
                             note: "r" * (Gemcutter::MAX_FIELD_LENGTH + 1))
      refute ownership_call.valid?
      assert_contains ownership_call.errors[:note], "is too long (maximum is 255 characters)"
    end

    should "not create a call without email" do
      ownership_call = build(:ownership_call, user: @user, rubygem: @rubygem,
                             email: nil)
      refute ownership_call.valid?
      assert_contains ownership_call.errors[:email], "can't be blank"
    end

    should "not create a call with invalid email" do
      ownership_call = build(:ownership_call, user: @user, rubygem: @rubygem,
                             email: "wrong email")
      refute ownership_call.valid?
      assert_contains ownership_call.errors[:email], "is invalid"
    end

    should "not create multiple open calls for a rubygem" do
      create(:ownership_call, user: @user, rubygem: @rubygem)
      ownership_call = build(:ownership_call, user: create(:user), rubygem: @rubygem)
      refute ownership_call.valid?
      assert_contains ownership_call.errors[:rubygem_id], "has already been taken"
    end
  end

  context "#close" do
    setup do
      @ownership_call = create(:ownership_call, user: @user, rubygem: @rubygem)
    end

    should "close all associated open requests and then call" do
      create_list(:ownership_request, 2, rubygem: @rubygem, ownership_call: @ownership_call)
      @ownership_call.close
      assert @ownership_call.closed?
      assert_empty @ownership_call.ownership_requests.opened
    end

    should "not close approved request" do
      create_list(:ownership_request, 2, rubygem: @rubygem, ownership_call: @ownership_call)
      approved_request = create(:ownership_request, :approved, rubygem: @rubygem, ownership_call: @ownership_call)
      @ownership_call.close
      assert_contains @ownership_call.ownership_requests.approved, approved_request
    end

    should "close call if no requests exist" do
      @ownership_call.close
      assert @ownership_call.closed?
      assert_empty @ownership_call.ownership_requests.opened
    end
  end

  context "#applied_by?" do
    setup do
      @ownership_call = create(:ownership_call, user: @user, rubygem: @rubygem)
    end

    context "user has applied" do
      setup do
        @applicant = create(:user)
        create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, user: @applicant)
      end
      should "return true" do
        assert @ownership_call.applied_by? @applicant
      end
    end

    context "user has not applied" do
      should "return false if user is nil" do
        refute @ownership_call.applied_by? nil
      end

      should "return false" do
        other_user = create(:user)
        refute @ownership_call.applied_by? other_user
      end
    end
  end
end
