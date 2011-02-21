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
$replies = YAML.load_file('replies.yml')

begin
  score = YAML::load_file('SCORE.yaml')
rescue
  score = {
    'started' => Time.now,
    'wtf' => 0,
    'facepalm' =>0
  }
end
SCORE = score

def reload! room, message
  return if message.nil? or not message.is_a? String
  unless message.match(/^RELOAD!/).nil?
    begin
      $replies = YAML.load_file('replies.yml')
      room.speak "RELOADED TEH $replies file"
    rescue
      room.speak "CANT RELOAD, file BORKED"
    end
  end
end

def update_score  room, message
  return if message.nil? or not message.is_a? String
  wat = message.match /^(wtf|facepalm)/i
  unless wat.nil?
    SCORE[wat.to_s.downcase] += 1
    room.speak "Since #{SCORE['started']} -> WTFs: #{SCORE['wtf']}, facepalms: #{SCORE['facepalm']}"
  end
  File.open('SCORE.yaml','w') { |f| YAML::dump(SCORE, f) }
end
def reply!(room, message)
  $replies.each_pair do |name, reply|
    if Regexp.new(reply['regex'], Regexp::IGNORECASE).match(message)
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
  'use_ssl' => true
}
room = Broach::Room.find CONFIG['room_id']

room.join

EventMachine::run do
  stream = Twitter::JSONStream.connect(options)

  stream.each_item do |item|
    puts item
    begin
      body = JSON.parse(item)['body']
    rescue => e
      puts "ERROR, #{e}"
      body = ""
    end

      reply! room,  body
      update_score room, body
      reload! room, body
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

