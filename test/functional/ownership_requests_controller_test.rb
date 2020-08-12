require "test_helper"

class OwnershipRequestsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on POST to create" do
      context "for popular gem" do
        setup do
          @rubygem = create(:rubygem, number: "1.0.0", downloads: 2_000_000)
        end
        context "when user is owner" do
          setup do
            create(:ownership, user: @user, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
          end
          should respond_with :forbidden
          should "not create ownership request" do
            assert_nil @rubygem.ownership_requests.find_by(user: @user)
          end
        end

        context "when user is not an owner" do
          context "ownership call exists" do
            setup do
              create(:ownership_call, rubygem: @rubygem)
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
            should "create ownership request" do
              assert_not_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end

          context "ownership call doesn't exist" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should respond_with :forbidden
            should "not create ownership request" do
              assert_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
        end
      end

      context "for less popular gem" do
        setup do
          @rubygem = create(:rubygem, number: "1.0.0", downloads: 2_000)
        end
        context "when user is owner" do
          setup do
            create(:ownership, user: @user, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
          end
          should respond_with :forbidden
          should "not create ownership request" do
            assert_nil @rubygem.ownership_requests.find_by(user: @user)
          end
        end

        context "when user is not an owner" do
          context "with correct params" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
            should "set success notice flash" do
              expected_notice = "Your ownership request is successfully submitted!"
              assert_equal expected_notice, flash[:notice]
            end
            should "create ownership request" do
              assert_not_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
          context "with missing params" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name }
            end
            should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
            should "set error alert flash" do
              expected_notice = "Note can't be blank"
              assert_equal expected_notice, flash[:alert]
            end
            should "not create ownership call" do
              assert_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
          context "when request from user exists" do
            setup do
              create(:ownership_request, rubygem: @rubygem, user: @user, note: "other note")
              post :create, params: { rubygem_id: @rubygem.name, note: "new note" }
            end
            should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
            should "set error alert flash" do
              expected_notice = "User has already been taken"
              assert_equal expected_notice, flash[:alert]
            end
          end
        end
      end
    end

    context "on PATCH to update" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0", downloads: 2_000_000)
      end
      context "when user is owner" do
        setup do
          create(:ownership, user: @user, rubygem: @rubygem)
        end
        context "on close" do
          setup do
            @requester = create(:user)
            request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "close" }
          end
          should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "Ownership request is closed successfully."
            assert_equal expected_notice, flash[:notice]
          end
          should "send email notifications" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 1
            assert_equal "Your ownership request was closed.", last_email.subject
            assert_equal [@requester.email], last_email.to
          end
        end

        context "on approve" do
          setup do
            @requester = create(:user)
            request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "approve" }
          end
          should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "Ownership request is approved! #{@user.display_id} is added as an owner."
            assert_equal expected_notice, flash[:notice]
          end
          should "add ownership record" do
            ownership = Ownership.find_by(rubygem: @rubygem, user: @requester)
            refute ownership.nil?
            assert ownership.confirmed?
          end
          should "send email notification" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 3
            request_approved_subjects = ActionMailer::Base.deliveries.map(&:subject)
            assert_contains request_approved_subjects, "Your ownership request was approved."
            assert_contains request_approved_subjects, "User #{@requester.handle} was added as an owner to #{@rubygem.name} gem"

            owner_removed_email_to = ActionMailer::Base.deliveries.map(&:to).flatten.uniq
            assert_same_elements @rubygem.owners.pluck(:email), owner_removed_email_to
          end
        end

        context "on incorrect status" do
          setup do
            @requester = create(:user)
            request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "random" }
          end
          should respond_with :not_found
        end
      end

      context "when user is not an owner" do
        setup do
          request = create(:ownership_request, rubygem: @rubygem)
          patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "close" }
        end
        should respond_with :not_found
      end
    end

    context "on GET to close" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0", downloads: 2_000_000)
      end
      context "when user is owner" do
        setup do
          create(:ownership, rubygem: @rubygem, user: @user)
          create_list(:ownership_request, 3, rubygem: @rubygem)
          get :close, params: { rubygem_id: @rubygem.name }
        end
        should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
        should "set success notice flash" do
          expected_notice = "All open ownership requests for #{@rubygem.name} are closed!"
          assert_equal expected_notice, flash[:notice]
        end
        should "close all open requests" do
          assert_empty @rubygem.ownership_requests
        end
      end

      context "user is not owner" do
        setup do
          create_list(:ownership_request, 3, rubygem: @rubygem)
          get :close, params: { rubygem_id: @rubygem.name }
        end
        should respond_with :forbidden
        should "not close all open requests" do
          assert_equal 3, @rubygem.ownership_requests.count
        end
      end
    end
  end

  context "when not logged in" do
    context "on POST to create" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
      end
      should redirect_to("sign in"){ sign_in_path }
    end

    context "on PATCH to update" do
      setup do
        ownership_request = create(:ownership_request)
        patch :update, params: { rubygem_id: ownership_request.rubygem_name, id: ownership_request.id, status: "closased" }
      end
      should redirect_to("sign in"){ sign_in_path }
    end

    context "on GET to close" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        create_list(:ownership_request, 3, rubygem: @rubygem)
        get :close, params: { rubygem_id: @rubygem.name }
      end
      should redirect_to("sign in"){ sign_in_path }
    end
  end
end
