require 'rubygems'

require 'yaml'
require 'broach'
require 'twitter/json_stream'


CONFIG = YAML.load_file('campfire_yellbot.yml')
REPLIES = YAML.load_file('campfire_yellbot_replies.yml')

def reply!(room, message)
  case message
#when /^rage$/ then room.speak "FFFFFUUUUU"
    when /^rage$/ then respond(room, 'rage')
    when /^ewbte$/ then respond(room, 'ewbte')
  end
end
def respond(room, match)
  room.speak(REPLIES[match]['message'].to_s)
  if REPLIES[match].include? 'image'
    room.speak(REPLIES[match]['image'])
  end
end

options = {
  :path => "/room/#{CONFIG['room_id']}/live.json",
  :host => 'streaming.campfirenow.com',
  :auth => "#{CONFIG['listen_token']}:x"
}

Broach.settings = {
  'account' => CONFIG['account'],
  'token'   => CONFIG['speak_token'],
  'use_ssl' => false
}
room = Broach::Room.find CONFIG['room_id']

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

