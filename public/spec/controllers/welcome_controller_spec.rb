require 'spec_helper'


describe WelcomeController, type: :controller do

  before (:each) do
    get :show
  end

  render_views # to check for partials being rendered
  
  it "should welcome all visitors" do
    expect(response).to have_http_status(200)
    expect(response).to render_template :show
  end

  it "renders partial templates" do
    expect(response).to render_template(partial: 'shared/_search')
    expect(response).to render_template(partial: 'shared/_metadata')
    expect(response).to render_template(partial: 'shared/_skipnav')
    expect(response).to render_template(partial: 'shared/_header')
    expect(response).to render_template(partial: 'shared/_navigation')
    expect(response).to render_template(partial: 'shared/_footer')
  end

end
