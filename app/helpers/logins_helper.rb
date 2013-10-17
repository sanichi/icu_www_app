module LoginsHelper
  def login_result_menu(selected)
    options_for_select(["Success", "Failure", "Bad email", "Bad password", "Expired", "Disabled", "Unverified", "Any"], selected)
  end

  def login_user_menu(selected)
    options_for_select(["Any user", "Has user", "No user"], selected)
  end
end
