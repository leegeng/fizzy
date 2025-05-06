require "test_helper"

class UndosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :jz
  end

  test "undo and destroy a command" do
    assert_includes cards(:logo).reload.assignees, users(:jz)

    assert_difference -> { users(:jz).commands.reload.count }, -1 do
      post command_undo_path(commands(:logo_assign_to_jz_command)), headers: { "HTTP_REFERER" => cards_path }
    end

    assert_not_includes cards(:logo).reload.assignees, users(:jz)

    assert_redirected_to cards_path
  end
end
