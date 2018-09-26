require 'spec_helper'
require 'rails_helper'

describe 'Search', js: true do
  before(:each) do
    visit('/')
    click_link 'Search The Archives'
    expect(current_path).to eq ('/search')
    finished_all_ajax_requests?
  end
  it 'should got to the correct page' do
    within all('.col-sm-12')[0] do
      expect(page).to have_content('Search The Archives')
    end
  end
  it 'should use an asterisk for a keyword search when no inputs and search button pressed' do
    click_on('submit_search')
    expect(page).to have_selector("div[class='searchstatement']", text: "keyword(s): *")
  end
end
