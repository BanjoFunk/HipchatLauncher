#require '/vagrant/launcher.rb'

# A HipChat controller for the Launcher.rb usb rocket launcher 
class Robut::Plugin::Banjobot
  include Robut::Plugin

  COMMANDS = 
        "   -- BanjoBot Commands -- \n \
        'targets' -> will return a list of available targets \n \
        'shoot <@name>' -> will fire a nerf missile at the target and deliver a random action movie catch-phrase. \n \
        'catchphrase' -> will deliver a random action movie catch-phrase."

  ADMIN_COMMANDS = 
        "   -- BanjoBot Admin Commands -- \n \
        'pause' -> will disable the 'shoot' command. \n \
        'start' -> will enable the 'shoot' command. (default) \n \
        'position' -> will return the current position \n \
        'set-position <@name>' -> will save new target with the current position. \n \
        'move <direction> <time>' -> will change the current position. *accepts 'right', 'left', 'up' and 'down'. time is in ms. \n \
        'reset' -> will reset the launcher position. \n \
        'add-target <@name> <x_position> <y_position>' -> will save new target with manual coordinates \n \
        'remove-target <@name>' -> will remove the target from the target list."

  CATCHPHRASES = [
        "'If you try to run, I’ve got six little friends and they can all run faster than you can.' — From Dusk Til Dawn",
        "'Say hello to my l'il friend.' -Tony Montana",
        "'Go ahead punk, make my day.' -Dirty Harry",
        "'Yippee kai yay...' -John McClain",
        "'This is my boomstick.' -Ash (army of darkness)",
        "'Hasta La Vista, Baby.' -The Terminator",
        "'I'm Your Huckleberry.' -Doc Holliday",
        "'Dyin' ain't much of a living.' -Outlaw Josey Wales",
        "'I know what you're thinking. 'Did he fire six shots or only five?' Well, to tell you the truth, in all this excitement, I kind of lost track myself.' -Dirty Harry",
        "'I love the smell of napalm in the morning.' -Lieutenant Colonel Bill Kilgore",
        "'Say 'What?' again!' - Samuel Jackson as Jules Winfield",
        "'And you will know my name is the lord, when i lay my vengeance upon thee' -Jules Winfield",
        "“Good, bad, I’m the guy with the gun.” – Bruce Campbell",
        " “The tyrannosaur doesn’t obey set patterns or park schedules. It’s the essence of Chaos.” – Jeff Goldblum",
        "'You're a big man, but you're out of shape. For me it's a full time job.' -Sylvester Stallone",
        "'To be or not to be? Not to be.' -Arnold Schwarzenegger",
        "'...let me do it my way. Just give me an eagle feather and a shotgun.' -Steven Seagal",
        "'Always bet on black.' -Wesley Snipes",
        "'Run! Go! Get to da choppaaaaaaa!' -Arnold Schwarzenegger",
        "'I ain't got time to bleed.' -Jesse 'The Body' Ventura",
        "'KHAAAN!' -William Shatner",
        "'I have come here to chew bubblegum and kick ass... and I'm all out of bubblegum.' -Rowdy Roddy Piper",
        "'Hey Batman, what killed the dinosaurs? The Ice Age!' -Arnold Schwarzenegger",
        "'I'm too old for this sh*t.' -Danny Glover",
        "'I'm gunna give you to the count of ten to get your ugly, yella, no good kiester of my property! One... Two... Ten!' -That movie in home alone"
      ]

  def handle(time, sender_nick, message)
    words = words(message)
    bot = Robut::Connection.config
    admin = bot.admin
    botname = bot.mention_name

##### User Commands

    if sent_to_me?(message) #|| sender_nick == admin

    # HELP
      if words.length == 1 && words.first.downcase == 'help'
        reply COMMANDS
      end

    # CATCHPHRASE
      if words.length == 1 && words.first.downcase == 'catchphrase'
        reply(CATCHPHRASES[rand(CATCHPHRASES.length)])
      end

    # PING
      if words.length == 1 && words.first.downcase == 'ping'
        reply "Pong #{sender_nick}"
      end

    # TARGETS
      if words(message).first == 'targets'
        m, a = [], targets 
        a.keys.sort.each { |key| m << "#{key} => [#{a[key][0]}, #{a[key][1]}]" }
        reply m.join("\n")
        return true
      end

    # SHOOT
      if words.length >= 2 && words.first.downcase == 'shoot'
        unless paused?
          l = Launcher.new
          targets = []
          words.each_with_index do |w, i|
            break if i == 5
            if w != words.first
              if target? w
                targets.push target w
                catch_phrase = CATCHPHRASES[rand(CATCHPHRASES.length)]
                reply "#{sender_nick} (nerf) #{w}", :room
              else
                reply w + " is not a known target..."
              end
            end
          end
          reply(CATCHPHRASES[rand(CATCHPHRASES.length)], :room) if targets.length > 0
          l.multi_launch(targets)
        else
          reply "Missile launcher has been paused for calibration..."
        end
      end

##### Admin Commands

      if sender_nick == admin

    # ADMIN-HELP
        if words.length == 1 && words.first.downcase == 'admin-help'
          reply ADMIN_COMMANDS
        end

    # PAUSE
        if words.length == 1 && words.first.downcase == 'pause'
          store['pause'] = 1
          reply "Pausing Missile launcher..."
          reply "Missile launcher has been paused for calibration.", :room
        end
    # START
        if words.length == 1 && words.first.downcase == 'start'
          store['pause'] = 0
          reply "Starting Missile launcher..."
          reply "Missile launcher is up and running!", :room
        end

    # POSITION
        if words.length == 1 && words.first.downcase == 'position'
          reply "x -> #{position_x}"
          reply "y -> #{position_y}"
          return true
        end

    # MOVE
        if words.length == 3 && words.first.downcase == 'move'
          l = Launcher.new
          l.move words[1], words[2]

          case words[1].to_s
          when 'right'
            store_position_x position_x + words[2].to_i
            reply "new x position is #{position_x}"
          when 'left'
            store_position_x position_x - words[2].to_i
            reply "new x position is #{position_x}"
          when 'up'
            store_position_y position_y + words[2].to_i
            reply "new y position is #{position_y}"
          when 'down'
            store_position_y position_y - words[2].to_i
            reply "new y position is #{position_y}"
          end
        end

    # RESET
        if words.length == 1 && words.first.downcase == 'reset'
          l = Launcher.new
          reply "resetting launcher."
          l.reset
          reset_position
        end

    # ADD-TARGET
        if words.length == 4 && words.first.downcase == 'add-target'
          store_target words[1], [words[2], words[3]]
          reply "#{words[1]} => right-#{words[2]} and up-#{words[3]}"
        end

        if words.length == 2 && words.first.downcase == 'set-position'
          store_position_as words[1]
          reply "#{words[1]} has been added to targets" #, :room
          l = Launcher.new
          l.reset
          reset_position
        end

    # REMOVE TARGET
        if words.first.downcase == 'remove-target'
          remove_target words.last
          reply "#{words.last} has been removed"
        end
      end

    end
  end

#====-------____## End Commands

  def store_position_x(x)
    store['position_x'] = x
    store['position_x'] = 0 if x < 0
    store['position_x'] = 5400 if x > 5400
  end

  def store_position_y(y)
    store['position_y'] = y
    store['position_y'] = 0 if y < 0
    store['position_y'] = 800 if y > 800
  end

  def reset_position
    store['position_x'] = 0
    store['position_y'] = 0
  end

  def store_position_as(key)
    value = [store['position_x'], store['position_y']]
    targets[key] = value
    store['targets'] = targets
  end

  def store_target(key, value)
    targets[key] = value
    store['targets'] = targets
  end

  def remove_target(key)
    new_target = targets
    new_target.delete(key)
    store['targets'] = new_target
  end

  def targets
    store['targets'] ||= {}
  end

  def target(name)
    store['targets'][name]
  end

  def target?(name)
    store['targets'][name] ? true : false
  end

  def pause
    store['pause'] ||= 0
  end

  def paused?
    store['pause'] == 0 ? true : false
  end

  def position_x
    store['position_x'] ||= 0
  end

  def position_y
    store['position_y'] ||= 0
  end

end
