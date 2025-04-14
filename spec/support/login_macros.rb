module LoginMacros
  def visit_login_page
    visit '/login'
  end

  def login_as_user(user)
    visit '/login'
    fill_in 'Eメール', with: user.email
    fill_in 'パスワード', with: '12345678'
    click_button 'ログイン'
    sleep 0.5
  end
end
