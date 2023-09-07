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
    @input_locked = true
  end

  def state
    $gtk.args.state
  end

  def draw
    # Display health bar.
    $gtk.args.outputs.sprites << @health_frame.merge(x: 10, y: 665)
    $gtk.args.outputs.sprites << @health_bar.merge(x: 20, y: 678)

    # Card choices.
    unless @input_locked
      if state.tutorial_done && choices.length == 3
        sprite_constants = {y: 550, x_scale: 0.1559, y_scale: 0.2525}

        draw_choice(x: 400, **sprite_constants)
        hud_text(choices[0].text, x: 400 + 44, y: 550 + 54)

        draw_choice(x: 576, **sprite_constants)
        hud_text(choices[1].text, x: 576 + 44, y: 550 + 54)

        draw_choice(x: 752, **sprite_constants)
        hud_text(choices[2].text, x: 722 + 44, y: 550 + 54)
      else
        raise "Invalid number of choices!"
      end
    end

    # Tutorial window.
    unless state.tutorial_done
      draw_choice(x: 370, y: 196, x_scale: 0.8, y_scale: 0.8)
      hud_text("Welcome to the game!", x: 550, y: 310)
      hud_text("Play each turn by choosing from three action cards.", x: 430, y: 360)
      hud_text("Use movement and abilities to avoid taking damage.", x: 430, y: 390)
      hud_text("Heal yourself by collecting potions.", x: 430, y: 420)
      hud_text("Make it to the end of the level to win!", x: 430, y: 450)
      hud_text("Click anywhere to continue.", x: 530, y: 510)
    end

    # Game Over text.
    if state.screen.complete?
      draw_choice(x: 436, y: 266, x_scale: 0.5, y_scale: 0.25) # Backdrop.
      $gtk.args.outputs.labels << [530, 290, "You win!"]
      # @big_font.draw_text("You win!", 530, 290, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      # hud_text('Click to play again.', x: 565, y: 355) # TODO: Add this feature.
      hud_text("Press ESC to quit.", x: 565, y: 355)
      state.input_locked = true # Hide choices.
    end

    if state.player.health.zero? # Player dead.
      draw_choice(x: 436, y: 266, x_scale: 0.5, y_scale: 0.25) # Backdrop.
      $gtk.args.outputs.lables << [500, 290, "Game over!"]
      # @big_font.draw_text("Game over!", 500, 290, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      # hud_text('Click to play again.', x: 565, y: 355) # TODO: Add this feature.
      hud_text("Press ESC to quit.", x: 565, y: 355)
      state.input_locked = true # Hide choices.
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
      $gtk.args.outputs.lines << {x: x, y: 0, x2: x, y2: 720, r: 0, g: 0, b: 0, a: 255}
      # Gosu.draw_line(
      #   x, 0, Gosu::Color::BLACK,
      #   x, 720, Gosu::Color::BLACK
      # )
    end
    72.step(720, 72).each do |y|
      $gtk.args.outputs.lines << {x: 0, y: y, x2: 1280, y2: y, r: 0, g: 0, b: 0, a: 255}
      # Gosu.draw_line(
      #   0, y, Gosu::Color::BLACK,
      #   1280, y, Gosu::Color::BLACK
      # )
    end
  end

  def hud_text(text, x:, y:)
    $gtk.args.outputs.labels << [x, y + 20, text, -1]
  end

  def draw_choice(x:, y:, x_scale:, y_scale:)
    w, h = *@choice_sprite.values_at(:w, :h)
    $gtk.args.outputs.sprites << @choice_sprite.merge(x: x, y: y, w: w * x_scale, h: h * y_scale)
  end

  def action_for_coordinates(x, y)
    offset = 128
    y_static = 40

    if y.between?(y_static, y_static + offset)
      return choices[0] if x.between?(400, 400 + offset)
      return choices[1] if x.between?(576, 576 + offset)
      choices[2] if x.between?(752, 752 + offset)
    end
  end

  def finish_tutorial!
    state.tutorial_done = true
    @input_locked = false
  end

  def handle_input
    if inputs.mouse.click
      if inputs.mouse.click.inside_rect?(@mute_sprite)
        args.audio[:music].gain = state.muted ? 1 : 0
        state.muted = !state.muted
      end
    end
  end
end
