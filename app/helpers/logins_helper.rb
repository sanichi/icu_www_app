module LoginsHelper
  def login_result_menu(selected)
    options_for_select(["Success", "Failure", "Bad password", "Expired", "Disabled", "Unverified", "Any"], selected)
  end
end
