require 'broach'
require 'twitter/json_stream'

def reply!(room, message)
  case message
    when /^rage$/
      room.speak('ffffffffuuuuuuuuu')
  end
end

config = YAML.load_file('campfire_yellbot.yml')

options = {
  :path => "/room/#{config['room_id']}/live.json",
  :host => 'streaming.campfirenow.com',
  :auth => "#{config['listen_token']}:x"
}

Broach.settings = {
  'account' => config['account'],
  'token'   => config['speak_token'],
  'use_ssl' => false
}
room = Broach::Room.find config['room_id']

EventMachine::run do
  stream = Twitter::JSONStream.connect(options)

  stream.each_item do |item|
    puts item
    item = JSON.parse(item)
    reply! room, item['body']
  end

  stream.on_error do |message|
    puts "ERROR:#{message.inspect}"
  end

  stream.on_max_reconnects do |timeout, retries|
    puts "Tried #{retries} times to connect."
    exit
  end
end

