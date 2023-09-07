# frozen_string_literal: true

class Level < Screen
  ADVANCE_DURATION = 2.seconds

  def initialize
    @stage = 0
    @level_pos_x = 0
    @level_scale = 0.5625 # 1280px to 720px.
    @level_sprite = {
      dim_x: 5120,
      dim_y: 1280,
      path: "sprites/gosu/levels/level1.png"
    }

    @fg_speed = 4.0
    @bg_speed = 2.0
    @bg_scale = 0.7032 # 1024px to 720px.
    @bg_image = {
      dim_x: 1024,
      dim_y: 1024,
      path: "sprites/gosu/background/colored_grass.png"
    }

    @spike_sprite = {
      dim_x: 128,
      dim_y: 128,
      path: "sprites/gosu/environment/spikes.png"
    }

    @potion_sprite = {
      dim_x: 128,
      dim_y: 128,
      path: "sprites/gosu/items/potionRed.png"
    }

    @floor_heights = [520, 304, 88].reverse # 1F, 2F, 3F. Pixels.

    @ui = UI.new
    @player = $gtk.args.state.player = Player.new(0, 72, self)
  end

  def draw
    bg_positions.each do |x|
      outputs.sprites << sprite_values(@bg_image, x, 0, @bg_scale)
    end

    outputs.sprites << sprite_values(@level_sprite, @level_pos_x, 0, @level_scale)

    spike_positions.each do |(x, y)|
      outputs.sprites << sprite_values(@spike_sprite, x, y - 268, 0.75)
    end

    potion_positions.each do |(x, y)|
      outputs.sprites << sprite_values(@potion_sprite, x, y - 515, 0.75)
    end

    @ui.draw
    @player.draw
  end

  def handle_input
    @ui.handle_input
    if inputs.mouse.click
      if state.tutorial_done
        card = @ui.action_for_click(inputs.mouse.click)
        return if complete? || card.nil?

        @input_locked = true # Unlocked when stage ends.
        @player.handle_action(card)
        advance_stage! unless card.is_a?(ConcentrateCard)
      else
        @ui.finish_tutorial!
      end
    end
  end

  def sprite_values(sprite, x, y, scale = 1.0)
    [x, y, *sprite.values_at(:dim_x, :dim_y).map { |val| val * scale }, sprite[:path]]
  end

  def spike_positions
    @spike_positions ||= [
      # Stage 1.
      [510, 554],
      [750, 338],
      # Stage 3.
      [1380, 338],
      [1610, 338],
      # Stage 4.
      [1660, 554],
      [1760, 554],
      [1810, 120],
      [2040, 120],
      [2060, 554],
      [2160, 554],
      # Stage 5.
      [2240, 338],
      [2480, 554],
      [2470, 338]
      # Example solution: Jump, Walk, Walk, Walk, Jump (grab potion above), Walk.
    ]
  end

  def potion_positions
    @potion_positions ||= [
      [1060, 570],
      [1920, 136]
    ]
  end

  def remove_potion(index)
    potion_positions.delete_at(index)
  end

  def elevation_map
    @elevation_map ||= {
      0 => [true, false, false], # Starting stage, not accessed.
      1 => [true, true, false],
      2 => [true, false, true],
      3 => [true, true, false],
      4 => [true, false, true],
      5 => [true, true, false],
      6 => [true, false, false]
    }
  end

  def bg_positions
    @bg_positions ||= (-1..3).map { |x| x * @bg_image[:dim_x] * @bg_scale }
  end

  def complete?
    @state == 6
  end

  def skip_stage
    state.skip_stage_start ||= DateTime.now
    @ui.lock!

    # Thread.new do
    #   sleep 0.75
    #   @input_locked = false
    # end
    #
    # @input_locked = true
  end

  def next_stage
    clamped_stage(@stage + 1)
  end

  def advance_stage!
    state.advance_stage_start = DateTime.now

    # Thread.new do
    #   sleep GameWindow.advance_duration
    #   $gtk.args.state.advancing = false
    #   Thread.new do
    #     # Unlock input a short time after advancing completes.
    #     sleep 0.25
    #     @input_locked = complete?
    #   end
    #   @stage = next_stage unless @player.dead
    # end

    next_elevations
  end

  def next_elevations
    @elevation_map[next_stage]
  end

  def clamped_stage(candidate_stage)
    candidate_stage.clamp(*@elevation_map.keys.minmax_by { |k, _v| k })
  end

  def tick
    if (advance_start = state.advance_stage_start)
      if DateTime.now >= advance_start + 0.75
        @ui.unlock!
        state.advance_stage_start = nil
      end

      if DateTime.now >= advance_start + Level::ADVANCE_DURATION
        @stage = next_stage unless @player.dead
        if DateTime.now >= advance_start + 0.25.seconds
          @input_locked = complete?
          state.advance_stage_start = nil
        end
      end
    end
  end
end
