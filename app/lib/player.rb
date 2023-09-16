# frozen_string_literal: true

class Player
  include AttrGTK

  attr_reader :dead, :health

  def initialize(x, y, level)
    @level = level
    @x = x
    @y = y
    @x_scale = 1
    @y_scale = 1
    @floor_heights = [72, 290, 500] # 1F, 2F, 3F. Pixels.
    @current_elevation = 0 # 1F.

    @sprite_stand = Constants.gosu_sprite("character/alienBlue_stand-cropped.png", w: 107, h: 147).merge(x: x, y: y)
    @sprite_jump = Constants.gosu_sprite("character/alienBlue_jump-cropped.png", w: 108, h: 153).merge(x: x, y: y)
    @sprite_walk = [
      Constants.gosu_sprite("character/alienBlue_walk1-cropped.png", w: 108, h: 152).merge(x: x, y: y),
      Constants.gosu_sprite("character/alienBlue_walk2-cropped.png", w: 112, h: 156).merge(x: x, y: y)
    ]
    @walk_anim = @sprite_walk
    @current_sprite = @sprite_stand
    @is_walking = false

    @jump_impulse = 22.0 # Pixels per frame.
    @jump_gravity = 31.0 # Pixels per square second.
    @jump_start_time = nil
    @is_jumping = false
    @is_falling = false

    @walk_sound = {input: "sounds/walk.mp3", looping: true, paused: true}
    @jump_sound = {input: "sounds/jump.mp3", looping: false}
    @concentrate_sound = {input: "sounds/concentrate.mp3", looping: false}

    # Health and damage.
    @health = 1.0
    @dead = false
    @invulnerable = false
    @damage_sound = {input: "sounds/damage.mp3", looping: false}
    @enable_debug = true
  end

  # Actions occur once per turn/stage.
  def handle_action(action)
    case action
    when WalkCard then walk
    when JumpCard then jump
    when ConcentrateCard then concentrate
    else raise "unknown action! (#{action})"
    end
  end

  # Collision is performed via jank. Check bounds of sprites for spikes and potions.
  def detect_collision
    return if dead

    @level.spike_sprites.each do |spike|
      next if @invulnerable
      next unless spike.intersect_rect?(current_sprite)

      # Take damage.
      @health = [@health - 0.2, 0].max
      audio[:damage] ||= @damage_sound.merge(gain: 0.5)

      # Prevent taking damage for the time it takes to walk through the spikes.
      @invulnerable = true
      state.invulnerable_at = state.tick_count
    end

    @level.potion_sprites.each.with_index do |potion, i|
      if potion.intersect_rect?(current_sprite)
        # Gain 1 HP.
        @health += 0.2 unless @health >= 1.0

        # Remove the potion from the level
        @level.remove_potion(i)
      end
    end
  end

  def detect_death
    if @health <= 0
      @invulnerable = true
      @dead = true
      return true
    end
    false
  end

  # Locomotion is processed every frame.
  def update_locomotion
    return unless @is_jumping || @is_falling

    v = vert_velocity
    @y += v
    return unless v.negative?

    # We are now falling.
    @is_jumping = false
    @is_falling = true

    # Stop falling when we hit the ground.
    floor_height = @floor_heights[@current_elevation] or
      raise "nil floor height! current elevation: #{@current_elevation}"

    if @y <= floor_height
      @y = floor_height
      @is_falling = false
      walk(from_fall_landing: true)
    end
  end

  def walk(from_fall_landing: false)
    return if @is_walking || @is_falling || @is_jumping

    @is_walking = true
    state.walk_at = state.tick_count
    state.walking_after_landing = from_fall_landing

    audio[:walk] ||= @walk_sound
    audio[:walk].paused = false
    next_elevations = @level.next_elevations

    # Handle falling off current elevation when walking.
    if @current_elevation == 1 && !next_elevations[1]
      delay_fall
    elsif @current_elevation == 2 && !next_elevations[2]
      delay_fall
      delay_fall unless next_elevations[1]
    end
  end

  def delay_fall
    state.delay_fall_at ||= state.tick_count
  end

  def jump
    return if @is_jumping || @is_falling || @is_walking

    @jump_start_time = Time.now
    @is_jumping = true
    @current_sprite = @sprite_jump

    state.jump_at = state.tick_count
    state.walking_after_landing = true
    audio[:jump] ||= @jump_sound
    next_elevations = @level.next_elevations

    # Handle jumping to higher elevation.
    if @current_elevation.zero? && next_elevations[1]
      @current_elevation += 1
    elsif @current_elevation == 1 && next_elevations[2]
      @current_elevation += 1
    end

    # Handle falling off current elevation when jumping.
    if @current_elevation == 1 && (!next_elevations[1] && !next_elevations[2])
      @current_elevation -= 1
    elsif @current_elevation == 2 && !next_elevations[2]
      @current_elevation -= 1
      @current_elevation -= 1 unless next_elevations[1]
    end
  end

  def concentrate
    audio[:concentrate] ||= @concentrate_sound
    @level.skip_stage
  end

  # Calculate vertical velocity based on jumping and falling durations.
  # Kinematics: v2 = v1 * at.
  def vert_velocity
    return if @jump_start_time.nil?
    dt = Time.now - @jump_start_time
    @jump_impulse - @jump_gravity * dt
  end

  def reset_sprite
    @current_sprite = @sprite_stand
  end

  def draw
    # Make the player sprite flash when damage was taken.
    return if @invulnerable && ($gtk.args.state.tick_count / 100) % 2 == 0

    # Gosu.draw_rect(@x - 56, @y - 24, 112, 152, Gosu::Color::BLUE) if @enable_collision_debug
    if @is_walking
      @current_sprite = @walk_anim[state.walk_at.frame_index(2, 5, true).or(0)]
    end

    outputs.sprites << current_sprite
    outputs.borders << current_sprite.merge(b: 255) if @enable_debug
  end

  def current_sprite
    @current_sprite.merge(x: @x, y: @y)
  end

  def tick
    if state.invulnerable_at && state.invulnerable_at.elapsed_time >= 1.3.seconds
      @invulnerable = false
      state.invulnerable_at = nil
    end

    if state.delay_fall_at
      if state.delay_fall_at.elapsed_time >= Level::ADVANCE_DURATION / 2 + 0.1
        @current_elevation -= 1
        state.delay_fall_at = nil
        @is_falling = true
      end
    end

    if state.jump_at && state.jump_at.elapsed_time > Level::ADVANCE_DURATION
      @is_jumping = false
      state.jump_at = nil
    end

    if state.walk_at
      walk_time = if state.walking_after_landing
        Level::ADVANCE_DURATION / 2 - 0.4.seconds
      else
        Level::ADVANCE_DURATION
      end

      if state.walk_at.elapsed_time >= walk_time
        @is_walking = false
        @current_sprite = @sprite_stand
        state.walk_at = nil
        state.walking_after_landing = false
        audio[:walk].paused = true
      end
    end

    update_locomotion
    detect_collision
    detect_death
  end

  def serialize
    {}
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
