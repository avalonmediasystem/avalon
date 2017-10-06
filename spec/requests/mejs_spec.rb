require 'rails_helper'

describe 'mejs', type: :request do
  it 'stores the version of me.js supplied' do
    get '/mejs/4'
    expect(request.env['rack.session']['mejs_version']).to eq 4
  end

  it 'redirects to root' do
    expect(get '/mejs/4').to redirect_to(root_path)
  end

  it 'sets a flash message' do
    get '/mejs/4'
    expect(flash[:notice]).not_to be_empty
  end
end
