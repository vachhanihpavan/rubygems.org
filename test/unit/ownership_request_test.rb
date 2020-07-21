require "test_helper"

class OwnershipRequestTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem)
  end

  context "#factory" do
    should "be valid with factory" do
      assert build(:ownership_request, user: @user, rubygem: @rubygem).valid?
    end

    should "be valid with approved trait factory" do
      assert build(:ownership_request, :approved, user: @user, rubygem: @rubygem).valid?
    end

    should "be valid with close trait factory" do
      assert build(:ownership_request, :closed, user: @user, rubygem: @rubygem).valid?
    end

    should "be valid with ownership call trait factory" do
      assert build(:ownership_request, :with_ownership_call, user: @user, rubygem: @rubygem).valid?
    end

    should "be valid with ownership call and approved traits factory" do
      assert build(:ownership_request, :with_ownership_call, :approved, user: @user, rubygem: @rubygem).valid?
    end
  end

  context "#create" do
    should "create a call with open status" do
      ownership_request = @rubygem.ownership_requests.create(user: @user, note: "valid note")
      assert ownership_request.opened?
    end

    should "not create a call with note longer than 255 chars" do
      ownership_request = build(:ownership_request, user: @user, rubygem: @rubygem,
                             note: "r" * (Gemcutter::MAX_FIELD_LENGTH + 1))
      refute ownership_request.valid?
      assert_contains ownership_request.errors[:note], "is too long (maximum is 255 characters)"
    end

    should "not create multiple calls for same user and rubygem" do
      create(:ownership_request, user: @user, rubygem: @rubygem)
      ownership_request = build(:ownership_request, user: @user, rubygem: @rubygem)
      refute ownership_request.valid?
      assert_contains ownership_request.errors[:user_id], "has already been taken"
    end
  end

  context "#approve" do
    setup do
      @ownership_request = create(:ownership_request, user: @user, rubygem: @rubygem)
    end

    context "with correct params" do
      setup do
        @approver = create(:user)
        @ownership_request.approve(@approver)
      end
      should "update approver" do
        assert @ownership_request.approved?
        assert_equal @approver, @ownership_request.approver
      end

      should "create confirmed ownership" do
        ownership = Ownership.find_by(user: @user, rubygem: @rubygem)
        assert_equal @approver, ownership.authorizer
        assert ownership.confirmed?
      end
    end

    context "with incorrect params" do
      should "not update if approver is nil" do
        @ownership_request.approve(nil)
        refute @ownership_request.approved?
        assert_nil Ownership.find_by(user: @user, rubygem: @rubygem)
      end
    end
  end

  context "#can_close?" do
    setup do
      @ownership_request = create(:ownership_request, user: @user, rubygem: @rubygem)
    end

    should "return true if created by self" do
      assert @ownership_request.can_close? @user
    end

    should "return true if owned by user" do
      other_user = create(:user)
      create(:ownership, user: other_user, rubygem: @rubygem)
      assert @ownership_request.can_close? other_user
    end

    should "return false if cannot close" do
      other_user = create(:user)
      refute @ownership_request.can_close? other_user
    end
  end
end
