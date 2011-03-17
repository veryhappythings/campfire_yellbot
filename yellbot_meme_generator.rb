require 'meme'

class YellbotMemeGenerator
  def meme? message
    Meme::GENERATORS.keys.each do |key|
      if message.start_with? key
        puts 'MEME DETECTED'
        return true
      end
    end
    false
  end

  def reply message
    meme_name, lines = message.split(' ', 2)
    line1, line2 = lines.split('|')

    puts meme_name
    puts line1
    puts line2

    meme = Meme.new meme_name
    link = meme.generate line1, line2
    puts link
    link
  end
end
