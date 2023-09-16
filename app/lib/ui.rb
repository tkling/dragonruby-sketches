# frozen_string_literal: true

class UI
  attr_reader :choices

  def initialize
    @hud_font = 20
    @big_font = 64
    @health_frame = Constants.gosu_sprite("hud/health_frame.png", w: 571 * 0.5, h: 83 * 0.5)
    @health_bar = Constants.gosu_sprite("hud/health_bar.png", w: 529 * 0.5, h: 38 * 0.5)
    @choice_sprite = Constants.gosu_sprite("hud/window.png", w: 821, h: 507)
    @mute_sprites = {
      mute: Constants.gosu_sprite("items/flagGreen1.png", w: 64, h: 64),
      muted: Constants.gosu_sprite("items/flagRed2.png", w: 64, h: 64)
    }
    @choices = [WalkCard.new, JumpCard.new, ConcentrateCard.new]
    @enable_debug_grid = true
    @input_locked = false
  end

  def state
    $gtk.args.state
  end

  def outputs
    $gtk.args.outputs
  end

  def inputs
    $gtk.args.inputs
  end

  def args
    $gtk.args
  end

  def audio
    $gtk.audio
  end

  def draw
    # Display health bar.
    outputs.sprites << @health_frame.merge(x: 10, y: 665)
    outputs.sprites << @health_bar.merge(x: 20, y: 678, w: @health_bar[:w] * state.player.health)

    # Card choices.
    unless @input_locked
      if state.tutorial_done
        raise "Invalid number of choices!" unless choices.length == 3
        sprite_constants = {y: 550, x_scale: 0.1559, y_scale: 0.2525}

        draw_choice(x: 400, entity: choices[0], **sprite_constants)
        hud_text(choices[0].text, x: 400 + 44, y: 550 + 54)

        draw_choice(x: 576, entity: choices[1], **sprite_constants)
        hud_text(choices[1].text, x: 576 + 44, y: 550 + 54)

        draw_choice(x: 752, entity: choices[2], **sprite_constants)
        hud_text(choices[2].text, x: 722 + 44, y: 550 + 54)
      end
    end

    # Tutorial window.
    unless state.tutorial_done
      draw_choice(x: 382, y: 148, x_scale: 0.645, y_scale: 0.6)
      hud_text("Welcome to the game!", x: 559, y: 390)
      hud_text("Play each turn by choosing from three action cards.", x: 420, y: 338)
      hud_text("Use movement and abilities to avoid taking damage.", x: 420, y: 308)
      hud_text("Heal yourself by collecting potions.", x: 420, y: 278)
      hud_text("Make it to the end of the level to win!", x: 420, y: 248)
      hud_text("Click anywhere to continue.", x: 528, y: 185)
    end

    # Game Over text.
    if state.screen.complete?
      draw_choice(x: 436, y: 266, x_scale: 0.5, y_scale: 0.25) # Backdrop.
      outputs.labels << [500, 370, "You win!"]
      hud_text("Press 'r' play again.", x: 565, y: 315)
      hud_text("Press ESC to quit.", x: 565, y: 285)
      @input_locked = true # Hide choices.
    end

    if state.player.dead # Player dead.
      audio.delete :damage if audio.key? :damage
      draw_choice(x: 436, y: 266, x_scale: 0.5, y_scale: 0.25) # Backdrop.
      outputs.labels << [500, 370, "Game over!"]
      hud_text("Press 'r' play again.", x: 565, y: 315)
      hud_text("Press ESC to quit.", x: 565, y: 285)
      @input_locked = true # Hide choices.
    end

    # Level debug grid.
    draw_debug_grid if @enable_debug_grid

    # Mute button.
    mute_sprite = state.muted ? @mute_sprites[:muted] : @mute_sprites[:mute]
    outputs.sprites << @mute_sprite = mute_sprite.merge(x: 1180, y: 630)
  end

  # Draws a grid of columns (x values) and rows (y values) for checking pixel precision.
  def draw_debug_grid
    72.step(1280, 72).each do |x|
      outputs.lines << {x: x, y: 0, x2: x, y2: 720, r: 0, g: 0, b: 0, a: 255}
    end
    72.step(720, 72).each do |y|
      outputs.lines << {x: 0, y: y, x2: 1280, y2: y, r: 0, g: 0, b: 0, a: 255}
    end
  end

  def hud_text(text, x:, y:)
    outputs.labels << [x, y + 20, text, -1]
  end

  def draw_choice(x:, y:, x_scale:, y_scale:, entity: nil)
    w, h = *@choice_sprite.values_at(:w, :h)
    sprite = @choice_sprite.merge(x: x, y: y, w: w * x_scale, h: h * y_scale)
    choice_map[sprite] = entity
    outputs.sprites << sprite
  end

  def choice_map
    @choice_map ||= {}
  end

  def action_for_click(click_point)
    choice_map.keys
      .find { |sprite| click_point.inside_rect?(sprite) }
      .yield_self { |sprite| @choice_map[sprite] }
  end

  def finish_tutorial!
    state.tutorial_done = true
    unlock!
  end

  def handle_input
    if inputs.mouse.click&.inside_rect?(@mute_sprite)
      args.audio[:music].gain = state.muted ? 1 : 0
      state.muted = !state.muted
    end
  end

  def lock!
    @input_locked = true
  end

  def unlock!
    @input_locked = false
  end

  def locked?
    @input_locked
  end
end
