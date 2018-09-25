require 'spec_helper'


describe RequestsController, type: :controller do

  it "should make a request" do
    AppConfig[:pui_request_email_fallback_from_address] = 'from_address@example.com'
    AppConfig[:pui_request_email_fallback_to_address] = 'to_address@example.com'

    post :make_request, :params => { user_name: "User Name", user_email: 'user_name@example.com', request_uri: '/repositories/2/resources/1' }
    expect(response.status).to eq(302)
  end

end
