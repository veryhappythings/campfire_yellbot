# Yellbot
Is your campfire room not cluttered enough?  Use yellbot to annoy all your co-workers.

It'll need a listen token, which needs to be someone in the room, and a speaking token, which is whoever you want to say things.  It'll need a room id too, and it'll need to know your account.  Use the config file for that.

# Get started

1. clone it
2. (you need rubygems and bundler)
3. `bundle install`
4. ??????
5. profit

# Configuration

Edit the config files (duh).

Configure your replies in `campfire_yellbot_replies` using this format:

    match:
      message: your message
      image: url to an image [optional]
