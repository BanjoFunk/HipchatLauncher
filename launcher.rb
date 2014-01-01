require "usb"

class Launcher

  COMMANDS = { :up => "\x02\x02\x00\x00\x00\x00\x00\x00",
               :down => "\x02\x01\x00\x00\x00\x00\x00\x00",
               :left => "\x02\x04\x00\x00\x00\x00\x00\x00",
               :right => "\x02\b\x00\x00\x00\x00\x00\x00",
               :stop => "\x02 \x00\x00\x00\x00\x00\x00",
               :fire => "\x02\x10\x00\x00\x00\x00\x00\x00" }

  TARGETS = { :brian => [2000, 500],
              :paul => [1000, 400],
              :bob => [5000, 1000] }

  def initialize
    @launcher = USB.devices.select { |d| d.idVendor == 0x2123 && d.idProduct == 0x1010 }.first
    raise "Cannot find missle launcher." unless @launcher
    @launcher.open do |h|
      begin
        h.usb_detach_kernel_driver_np 0, 0
      rescue Errno::ENODATA => e
      end
    end
  end

  def target?(name)
    TARGETS[name.downcase.to_sym] ? true : nil
  end

  def move(dir, time)
    execute dir.to_sym
    sleep time.to_i * 0.001
    execute :stop
  end
  
  def fire
    execute :fire
    sleep 3
  end

  def reset
    move(:left, 6000)
    move(:down, 2000)
  end

  def multi_launch(targets)
    current_x = 0
    current_y = 0

    targets.each do |t|

      if t.kind_of? Array
        target_x = t[0].to_i
        target_y = t[1].to_i
      else
        name = t.downcase.to_sym
        target_x = TARGETS[name][0]
        target_y = TARGETS[name][1]
      end

      diff_x = target_x - current_x
      diff_y = target_y - current_y
      current_x = target_x
      current_y = target_y

      diff_x < 0 ? move(:left, diff_x.abs) : move(:right, diff_x)
      diff_y < 0 ? move(:down, diff_y.abs) : move(:up, diff_y)
      fire
    end
    move(:left, current_x + 500)
    move(:down, current_y + 500)
  end



  private

    def execute(command)
      @launcher.open { |h| h.usb_control_msg 0x21, 0x09, 0, 0, COMMANDS[command], 0 }
    end

end
