require 'rubygems'

require 'yaml'
require 'broach'
require 'twitter/json_stream'

require 'broach_monkeypatch'
require 'yellbot_meme_generator'

CONFIG = YAML.load_file('config.yml')
$replies = YAML.load_file('replies.yml')
@meme_generator = YellbotMemeGenerator.new
begin
  score = YAML::load_file('SCORE.yaml')
rescue
  score = {
    'started' => Time.now,
    'wtf' => 0,
    'facepalm' => 0
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
  unless wat.nil? or wat.to_s.nil?
    SCORE[wat.to_s.downcase] += 1
    room.speak "Since #{SCORE['started']} -> WTFs: #{SCORE['wtf']}, facepalms: #{SCORE['facepalm']}"
  end
  File.open('SCORE.yaml','w') { |f| YAML::dump(SCORE, f) }
end

def reply(room, message)
  $replies.each_pair do |name, reply|
    if Regexp.new(reply['regex'], Regexp::IGNORECASE).match(message)
      respond(room, reply)
    end
  end
  if @meme_generator.meme? message
    respond(room, {'message' => [@meme_generator.reply(message)]})
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
      obj = JSON.parse(item)
      body = obj['body']
      user_id = obj['user_id']
    rescue => e
      puts "ERROR, #{e}"
      body = ""
    end

    begin
      if user_id != CONFIG['bot_user_id']
        reply room,  body
        update_score room, body
        reload! room, body
      end
    rescue => e
      puts "ERROR, ERRROR"
      y e
    end
  end

  stream.on_error do |message|
    begin
      puts message
      puts "ERROR:#{message.inspect}"
    rescue => e
      puts "ERROR, ERRROR"
      y e
    end

  end

  stream.on_max_reconnects do |timeout, retries|
    puts "Tried #{retries} times to connect."
    exit
  end
end

