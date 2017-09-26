class Neko::Request
  method_object :params

  URL = 'http://localhost:4000/user_rate'

  def call
    response = post_request(@params)
    failure! response if failed? response

    data = JSON.parse response.body, symbolize_names: true

    {
      added: parse(data[:added]),
      updated: parse(data[:updated]),
      removed: parse(data[:removed])
    }
  end

private

  def post_request params
    Faraday.post do |req|
      req.url URL
      req.headers['Authorization'] = 'foo'
      req.headers['Content-Type'] = 'application/json'
      req.body = params.to_json
    end
  end

  def parse achievements
    achievements.map do |achievement|
      Neko::AchievementData.new achievement
    end
  end

  def failed? response
    ![200, 201].include?(response.status)
  end

  def failure! response
    raise(
      "#{response.status} #{response.reason_phrase} #{response.body}".strip
    )
  end
end
