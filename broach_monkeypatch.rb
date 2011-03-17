
module Broach
  class Session
    def post_empty(path, payload)
      response = REST.post(url_for(path), payload.to_json, headers_for(:post), credentials)
      if response.created?
        JSON.parse(response.body)
      end
    end
  end

  class Room
    def join
      Broach.session.post_empty("room/#{id.to_i}/join.xml", '')
    end

    def leave
      Broach.session.post_empty("room/#{id.to_i}/leave.xml", '')
    end
  end
end
