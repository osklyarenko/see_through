require 'sinatra/base'

class FakeGitHub < Sinatra::Base
  get '/repos/sasha-kantoriz/test/pulls/:number.diff' do |number|
    json_response 200, "PRs_diff", "pr_#{number}.diff"
  end

  get '/repos/sasha-kantoriz/test/issues/:number' do |number|
    json_response 200, "PRs_labels", "pr_#{number}.labels"
  end

  private

  def json_response(response_code, fixture_dir, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + "/fixtures/Github/#{fixture_dir}/" + file_name, 'rb').read
  end
end