require "test_helper"

class OwnershipCallsControllerTest < ActionController::TestCase

  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    teardown do
      sign_out
    end

    context "on GET to show" do
      context "user is owner of obscure rubygem" do
        setup do
          @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
        end

        context "ownership call exists" do
          setup do
            @ownership_call = create(:ownership_call, rubygem: @rubygem, user: @user)
          end

          context "ownership request exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end
        end

        context "ownership call doesn't exist" do
          context "ownership request exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end
        end
      end

      context "user is owner of popular rubygem" do
        setup do
          @rubygem = create(:rubygem, owners: [@user], number: "1.0.0", downloads: 200_000)
        end

        context "ownership call exists" do
          setup do
            @ownership_call = create(:ownership_call, rubygem: @rubygem, user: @user)
          end

          context "ownership request exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end
        end

        context "ownership call doesn't exist" do
          context "ownership request exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :not_found
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :not_found
          end
        end
      end

      context "user is not owner of rubygem" do
        setup do
          @rubygem = create(:rubygem, number: "1.0.0")
        end
        context "ownership call exists" do
          setup do
            @ownership_call = create(:ownership_call, rubygem: @rubygem)
          end

          context "ownership request by user exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, user: @user)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end
        end

        context "ownership call doesn't exist" do
          context "ownership request exists" do
            setup do
              @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, user: @user)
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end

          context "ownership request doesn't exist" do
            setup do
              get :show, params: { rubygem_id: @rubygem.name }
            end
            should respond_with :success
          end
        end
      end
    end

    context "on POST to create" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
      end

      context "user is owner of rubygem" do
        context "with correct params" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
          end
          should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "The ownership call for #{@rubygem.name} is now open!"
            assert_equal expected_notice, flash[:notice]
          end
          should "create a call" do
            assert_not_nil @rubygem.ownership_calls.find_by(user: @user)
          end
        end

        context "with params missing" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
          should "set alert flash" do
            expected_alert = "Note can't be blank"
            assert_equal expected_alert, flash[:alert]
          end
          should "not create a call" do
            assert_nil @rubygem.ownership_calls.find_by(user: @user)
          end
        end

        context "when call is already open" do
          setup do
            create(:ownership_call, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "other small note" }
          end
          should redirect_to("ownerships calls show") { rubygem_ownership_calls_path(@rubygem) }
          should "set alert flash" do
            expected_alert = "Rubygem can have only one open ownership call"
            assert_equal expected_alert, flash[:alert]
          end
          should "not create a call" do
            assert_equal 1, @rubygem.ownership_calls.count
          end
        end
      end

      context "user is not owner of rubygem" do
        setup do
          user = create(:user)
          sign_in_as(user)
          post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
        end
        should respond_with :forbidden
        should "not create a call" do
          assert_nil @rubygem.ownership_calls.find_by(user: @user)
        end
      end
    end

    context "on PATCH to update" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
      end

      context "user is owner of rubygem" do
        context "ownership call exists" do
          setup do
            create(:ownership_call, rubygem: @rubygem, user: @user)
            patch :update, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("ownerships calls show") { rubygem_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "The ownership call for #{@rubygem.name} is successfully closed."
            assert_equal expected_notice, flash[:notice]
          end
          should "update status to close" do
            assert_empty @rubygem.ownership_calls
          end
        end

        context "ownership call does not exist" do
          setup do
            patch :update, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :not_found
        end
      end

      context "user is not owner of rubygem" do
        setup do
          user = create(:user)
          sign_in_as(user)
          create(:ownership_call, rubygem: @rubygem, user: @user)
          patch :update, params: { rubygem_id: @rubygem.name }
        end
        should respond_with :forbidden
        should "not update status to close" do
          assert_not_empty @rubygem.ownership_calls
        end
      end
    end
  end

  context "When user not logged in" do
    context "on GET to show" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        get :show, params: { rubygem_id: @rubygem.name }
      end
      should "redirect to sign in" do
        assert_redirected_to sign_in_path
      end
    end

    context "on POST to create" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
      end
      should "redirect to sign in" do
        assert_redirected_to sign_in_path
      end
      should "not create call" do
        assert_empty @rubygem.ownership_calls
      end
    end

    context "on PATCH to update" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        create(:ownership_call, rubygem: @rubygem)
        patch :update, params: { rubygem_id: @rubygem.name }
      end
      should "redirect to sign in" do
        assert_redirected_to sign_in_path
      end
      should "not close the call" do
        assert_not_empty @rubygem.ownership_calls
      end
    end

    context "on GET to index" do
      setup do
        rubygems = create_list(:rubygem, 3, number: "1.0.0")
        @ownership_calls = []
        rubygems.each do |rubygem|
          @ownership_calls << create(:ownership_call, rubygem: rubygem)
        end
        get :index
      end
      should respond_with :success
      should "not include closed calls" do
        ownership_call = create(:ownership_call, :closed)
        refute page.has_content? ownership_call.rubygem_name
      end
      should "order calls by created date" do
        expected_order = @ownership_calls.reverse.map(&:rubygem_name)
        actual_order = assert_select("a.gems__gem__name").map(&:text)

        expected_order.each_with_index do |expected_gem_name, i|
          assert_match(/#{expected_gem_name}/, actual_order[i])
        end
      end
      should "display entries and total in page info" do
        assert_select "header > p.gems__meter", text: /Displaying all 3 ownership calls/
      end
      should "display correct number of entries" do
        entries = assert_select("a.gems__gem__name")
        assert_equal(entries.size, 3)
      end
    end
  end
end
