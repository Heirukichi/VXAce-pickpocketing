#===============================================================================
# HEIRUKICHI PICKPOCKETING SCRIPT
#-------------------------------------------------------------------------------
# This script provides extra tools made to add pickpocketing mechanics to VX Ace
# games and to handle action results through events.
# 
#-------------------------------------------------------------------------------
# TERMS OF USE
#-------------------------------------------------------------------------------
# For terms of use and license check the script readme at the following link:
# https://github.com/Heirukichi/VXAce-pickpocketing/blob/main/README.md
#===============================================================================
$imported = {} if $imported.nil?
$imported[:HRK_Pickpocketing] = true
#===============================================================================
# ** HRK_PICKPOCKETING module
#===============================================================================
module HRK_PICKPOCKETING
  #=============================================================================
  # ** HRK_PICKPOCKETING::Config module
  #-----------------------------------------------------------------------------
  # Script configuration. Modify this part to fit your needs
  #=============================================================================
  module Config
    #---------------------------------------------------------------------------
    # Total width of the pickpocketing bar.
    # Default is 30.
    #---------------------------------------------------------------------------
    BAR_WIDTH = 240
    #---------------------------------------------------------------------------
    # Total height of the pickpocketing bar.
    # Default is 30.
    #---------------------------------------------------------------------------
    BAR_HEIGHT = 30
    #---------------------------------------------------------------------------
    # Pickpocketing bar distance from the bottom part of the screen.
    # Default is 30.
    #---------------------------------------------------------------------------
    BAR_BOTTOM_OFFSET = 30
    #---------------------------------------------------------------------------
    # Pickpocketing indicator vertical offset.
    # Default is 6.
    #---------------------------------------------------------------------------
    BAR_CURSOR_VERTICAL_OFFSET = 6
    #---------------------------------------------------------------------------
    # Used to define the cursor movement bounds. When moving to the utmost right
    # or utmost left, the cursor will always be this many pixels away from the 
    # window border.
    # Default is 10.
    #---------------------------------------------------------------------------
    BAR_CURSOR_HORIZONTAL_OFFSET = 10
    #---------------------------------------------------------------------------
    # Difficulty settings are defined here. Each difficulty has associated
    # values for sweet spot width and cursor speed. In case any of them is
    # missing in a configuration, a default value will be used.
    # It is possible to add more difficulties other than those already in the
    # list. Just keep in mind that :normal is used as a default when missing the
    # requested difficulty.
    #
    # Default values are the following:
    # - :sweet_spot_width => 60
    # - :cursor_speed => 4
    #---------------------------------------------------------------------------
    DIFFICULTY_SETTINGS = {
      :chill => {
        :sweet_spot_width => 100,
        :cursor_speed => 2
      },
      :easy => {
        :sweet_spot_width => 80,
        :cursor_speed => 3
      },
      :normal => {
        :sweet_spot_width => 60,
        :cursor_speed => 4
      },
      :hard => {
        :sweet_spot_width => 40,
        :cursor_speed => 5
      },
      :insane => {
        :sweet_spot_width => 20,
        :cursor_speed => 6
      }
    }
    #---------------------------------------------------------------------------
    # Color for the outer part of the sweet spot.
    # Default is [254, 244 0] (yellow).
    #---------------------------------------------------------------------------
    BAR_GAUGE_OUTER_COLOR = [254, 255, 0]
    #---------------------------------------------------------------------------
    # Color for the inner part of the sweet spot.
    # Default is [60, 255, 0] (green).
    #---------------------------------------------------------------------------
    BAR_GAUGE_INNER_COLOR = [60, 255, 0]
    #---------------------------------------------------------------------------
    # Debug setting. If set to false, debug messages are shown in the console.
    # Set it to true before release.
    # Default is false.
    #---------------------------------------------------------------------------
    DISABLE_DEBUG = false
  end # end of HRK_PICKPOCKETING::Config module
  ##
  ##
  ##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##
  ## WARNING!
  ##
  ##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##
  ## DO NOT MODIFY AFTER THIS PONT UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
  ##
  ##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##
  ##
  #=============================================================================
  # ** HRK_PICKPOCKETING::Debug module
  #-----------------------------------------------------------------------------
  # Used for debugging purposes
  #=============================================================================
  module Debug
    MESSAGES = {
      :no_such_difficulty => {
        :type => :ERROR,
        :text => [
          "Selected difficulty does not exist.",
          "    Default will be used. Check your event for errors."
        ]
      },
      :no_associated_settings => {
        :type => :ERROR,
        :text => [
          "Selected difficulty has no associated settings!",
          "    Default will be used. Check script configuration for errors."
        ]
      },
      :undefined_cursor_speed => {
        :type => :WARN,
        :text => [
          "Selected settings lack cursor speed. Was this intentional?",
          "    Default will be used. Check script configuration for errors."
        ]
      },
      :undefined_sweet_spot => {
        :type => :WARN,
        :text => [
          "Selected settings lack sweet spot width. Was this intentional?",
          "    Default will be used. Check script configuration for errors."
        ]
      }
    }
    def self.log_message(msg_code)
      return if HRK_PICKPOCKETING::Config::DISABLE_DEBUG
      message = MESSAGES[msg_code]
      type = message[:type].to_s || "INFO"
      texts = message[:text] || ["Message #{msg_code.to_s} missing text."]
      final_string = "#{type}: "
      texts.each do |t|
        final_string += "#{t}\n"
      end
      puts(final_string)
    end
  end # end of HRK_PICKPOCKETING::Debug module
  #=============================================================================
  # ** HRK_PICKPOCKETING::Runtime module
  #-----------------------------------------------------------------------------
  # Holds runtime data such as difficulty.
  #=============================================================================
  module Runtime
    #---------------------------------------------------------------------------
    # * Setter for difficulty
    #---------------------------------------------------------------------------
    def self.set_difficulty(difficulty)
      @difficulty = difficulty
    end
    #---------------------------------------------------------------------------
    # * Getter for difficulty
    #---------------------------------------------------------------------------
    def self.difficulty
      @difficulty || :normal
    end
    #---------------------------------------------------------------------------
    # * Setter for last pickpocketing result
    #---------------------------------------------------------------------------
    def self.store_last_pickpocketing_result(result)
      @last_result = result || false
    end
    #---------------------------------------------------------------------------
    # * Getter for last pickpocketing result
    #---------------------------------------------------------------------------
    def self.last_pickpocketing_result
      @last_result
    end
    #---------------------------------------------------------------------------
    # * Setter for event data
    #---------------------------------------------------------------------------
    def self.set_event_data(map, event, switch)
      @event_data = [map, event, switch]
    end
    #---------------------------------------------------------------------------
    # * Getter for event data
    #---------------------------------------------------------------------------
    def self.get_event_data
      @event_data
    end
  end # end of HRK_PICKPOCKETING::Runtime module
end
#===============================================================================
# ** Scene_Pickpocketing class
#-------------------------------------------------------------------------------
# Used to handle the whole pickpocketing scene and to separate it from standard
# Scene_Map processes.
#===============================================================================
class Scene_Pickpocketing < Scene_Base
  #-----------------------------------------------------------------------------
  # * Start Scene
  #-----------------------------------------------------------------------------
  def start
    super
    @difficulty = HRK_PICKPOCKETING::Runtime.difficulty
    @settings = HRK_PICKPOCKETING::Config::DIFFICULTY_SETTINGS[@difficulty]
    if (@settings.nil?)
      HRK_PICKPOCKETING::Debug.log_message(:no_associated_settings)
      @settings = {
        :sweet_spot_width => 60,
        :cursor_speed => 4
      }
    end
    if (@settings[:cursor_speed].nil?)
      HRK_PICKPOCKETING::Debug.log_message(:undefined_cursor_speed)
      @speed = 4
    else
      @speed = @settings[:cursor_speed]
    end
    if (@settings[:sweet_spot_width].nil?)
      HRK_PICKPOCKETING::Debug.log_message(:undefined_sweet_spot)
      @sweet_spot_width = 60
    else
      @sweet_spot_width = @settings[:sweet_spot_width]
    end
    cursor_padding = HRK_PICKPOCKETING::Config::BAR_CURSOR_HORIZONTAL_OFFSET
    @direction = 1
    @action_button_pressed = true
    create_background
    create_pickpocketing_window
  end
  #-----------------------------------------------------------------------------
  # * Terminate Scene
  #-----------------------------------------------------------------------------
  def terminate
    super
    dispose_background
  end
  #-----------------------------------------------------------------------------
  # * Create Pickpocketing Window
  #-----------------------------------------------------------------------------
  def create_pickpocketing_window
    create_pickpocket_bar
    create_gauge_bar
    create_position_cursor
  end
  #-----------------------------------------------------------------------------
  # * Create Position Cursor
  #-----------------------------------------------------------------------------
  def create_position_cursor
    width = HRK_PICKPOCKETING::Config::BAR_WIDTH
    height = HRK_PICKPOCKETING::Config::BAR_HEIGHT
    cursor_padding = HRK_PICKPOCKETING::Config::BAR_CURSOR_HORIZONTAL_OFFSET
    @cursor_position = rand(width - (cursor_padding + @speed) * 4) - width / 2
    x = (Graphics.width - width) / 2
    y = Graphics.height - height - HRK_PICKPOCKETING::Config::BAR_BOTTOM_OFFSET
    y_offset = HRK_PICKPOCKETING::Config::BAR_CURSOR_VERTICAL_OFFSET
    @cursor = Window_Base.new(x + @cursor_position, y + y_offset, width, 10)
    @cursor.opacity = 0
    @cursor.z = 3
  end
  #-----------------------------------------------------------------------------
  # * Create Pickpocket Bar
  #-----------------------------------------------------------------------------
  def create_pickpocket_bar
    width = HRK_PICKPOCKETING::Config::BAR_WIDTH
    height = HRK_PICKPOCKETING::Config::BAR_HEIGHT
    x = (Graphics.width - width) / 2
    y = Graphics.height - height - HRK_PICKPOCKETING::Config::BAR_BOTTOM_OFFSET
    @bar = Window_Base.new(x, y, width, height)
    @bar.arrows_visible = false
    @bar.back_opacity = 0
    @bar.z = 1
  end
  #-----------------------------------------------------------------------------
  # * Create Gauge Bar
  #-----------------------------------------------------------------------------
  def create_gauge_bar
    @border = Window_Base.new(@bar.x, @bar.y - 40, @bar.width, @bar.height + 80)
    @border.arrows_visible = false
    @border.opacity = 0
    @border.padding = 0
    @border.back_opacity = 0
    @border.z = 0
    outer_data = HRK_PICKPOCKETING::Config::BAR_GAUGE_OUTER_COLOR
    inner_data = HRK_PICKPOCKETING::Config::BAR_GAUGE_INNER_COLOR
    color_out = Color.new(outer_data[0], outer_data[1], outer_data[2])
    color_in = Color.new(inner_data[0], inner_data[1], inner_data[2])
    w = @sweet_spot_width / 2
    bar_x = (@bar.width - @sweet_spot_width) / 2
    x1 = bar_x - @border.padding
    x2 = x1 + w
    bar_h = @bar.height
    @border.contents.clear
    @border.contents.gradient_fill_rect(x1, 40, w, bar_h, color_out, color_in)
    @border.contents.gradient_fill_rect(x2, 40, w, bar_h, color_in, color_out)
  end
  #-----------------------------------------------------------------------------
  # * Create Background
  #-----------------------------------------------------------------------------
  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = SceneManager.background_bitmap
    @background_sprite.color.set(16, 16, 16, 128)
  end
  #-----------------------------------------------------------------------------
  # * Dispose Background
  #-----------------------------------------------------------------------------
  def dispose_background
    @background_sprite.dispose
    @border.dispose
    @cursor.dispose
    @bar.dispose
  end
  #-----------------------------------------------------------------------------
  # * Perform Pickpocketing
  #-----------------------------------------------------------------------------
  def perform_pickpocketing
    if (@cursor_position.abs < @sweet_spot_width / 2)
      puts("Target successfully pickpocketed")
      HRK_PICKPOCKETING::Runtime.store_last_pickpocketing_result(true)
    else
      puts("Pickpocketing attempt failed")
      HRK_PICKPOCKETING::Runtime.store_last_pickpocketing_result(false)
    end
    # $game_switches[HRK_PICKPOCKETING::Config::RESERVED_SWITCH_ID] = true
    $game_self_switches[HRK_PICKPOCKETING::Runtime.get_event_data] = true
    return_scene
  end
  #-----------------------------------------------------------------------------
  # * Update Input
  #-----------------------------------------------------------------------------
  def update_input
    if (Input.press?(:B))
      return_scene
      return
    end
    if (Input.press?(:C))
      perform_pickpocketing
      @action_button_pressed = true
    else
      @action_button_pressed = false
    end
  end
  #-----------------------------------------------------------------------------
  # * Update Animation
  #-----------------------------------------------------------------------------
  def update_animation
    cursor_padding = HRK_PICKPOCKETING::Config::BAR_CURSOR_HORIZONTAL_OFFSET
    total_padding = @speed + cursor_padding
    max_width = HRK_PICKPOCKETING::Config::BAR_WIDTH / 2 - total_padding
    if (@cursor_position <= -max_width || @cursor_position >= max_width)
      @direction *= -1 if @cursor_position * @direction > 0
    end
    @cursor_position += @direction * @speed
    new_x = @bar.x + @cursor_position
    @cursor.move(new_x, @cursor.y, @cursor.width, @cursor.height)
  end
  #-----------------------------------------------------------------------------
  # * Frame update
  #-----------------------------------------------------------------------------
  def update
    super
    update_animation
    @border.update
    @cursor.update
    @bar.update
    update_input
  end
end
#===============================================================================
# ** Game_Interpreter class
#-------------------------------------------------------------------------------
# Extension of Game_Interpreter class. Adds a new method to start pickpocketing.
# Checks to validate event position are already included.
#===============================================================================
class Game_Interpreter
  #-----------------------------------------------------------------------------
  # * Start Pickpocketing
  #-----------------------------------------------------------------------------
  def start_pickpocketing(self_switch, difficulty = :normal)
    player = $game_player
    event = $game_map.events[@event_id]
    x = $game_map.round_x_with_direction(player.x, player.direction)
    y = $game_map.round_y_with_direction(player.y, player.direction)
    if (event.x == x && event.y == y && event.direction == player.direction)
      if (HRK_PICKPOCKETING::Config::DIFFICULTY_SETTINGS[difficulty].nil?)
        HRK_PICKPOCKETING::Debug.log_message(:no_such_difficulty)
        HRK_PICKPOCKETING::Runtime.set_difficulty(:normal)
      else
        HRK_PICKPOCKETING::Runtime.set_difficulty(difficulty)
      end
      HRK_PICKPOCKETING::Runtime.set_event_data(@map_id, @event_id, self_switch)
      SceneManager.call(Scene_Pickpocketing)
    end
  end
  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def pickpocket_success?
    HRK_PICKPOCKETING::Runtime.last_pickpocketing_result
  end
end
