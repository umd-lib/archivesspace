require 'spec_helper'
require 'rails_helper'

describe 'RequestItem', js: true do
  it 'should accept a request that contains required information' do
    AppConfig[:pui_request_email_fallback_from_address] = 'from_address@example.com'
    AppConfig[:pui_request_email_fallback_to_address] = 'to_address@example.com'

    visit('/')
    click_link 'Collections'
    first_title = ''
    first_href = ''
    within all('.col-sm-12')[1] do
      first_title = first("a[class='record-title']").text
      href = first("a")['href'].split('/')
      first_href = '/' + href[3..href.length].join('/')
      first("a[class='record-title']").click
    end
    click_button 'Request'
    within('#request_form') do
      expect(page).to have_content('Your name required')
      fill_in(:user_name, :with => 'User Name')
      fill_in(:user_email, :with => 'user_name@example.com')
      click_button 'Request'
      expect(page).to have_content('Thank you, your request has been submitted. You will soon receive an email with a copy of your request.')
    end
  end
end
