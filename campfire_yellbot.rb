require 'rubygems'

require 'yaml'
require 'broach'
require 'twitter/json_stream'

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

CONFIG = YAML.load_file('config.yml')
REPLIES = YAML.load_file('replies.yml')

def reply!(room, message)
  REPLIES.each_pair do |name, reply|
    if Regexp.new(reply['regex']).match(message)
      respond(room, reply)
    end
  end
end

def respond(room, reply)
  reply['message'].each do |message|
    room.speak(message)
  end
end

options = {
  :path => "/room/#{CONFIG['room_id']}/live.json",
  :host => 'streaming.campfirenow.com',
  :auth => "#{CONFIG['token']}:x"
}

Broach.settings = {
  'account' => CONFIG['account'],
  'token'   => CONFIG['token'],
  'use_ssl' => false
}
room = Broach::Room.find CONFIG['room_id']

room.join

EventMachine::run do
  stream = Twitter::JSONStream.connect(options)

  stream.each_item do |item|
    puts item
    item = JSON.parse(item)
    reply! room, item['body']
  end

  stream.on_error do |message|
    puts message
    puts "ERROR:#{message.inspect}"
  end

  stream.on_max_reconnects do |timeout, retries|
    puts "Tried #{retries} times to connect."
    exit
  end
end

