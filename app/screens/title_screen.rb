# frozen_string_literal: true

require_relative 'level'

class TitleScreen < Screen
  def tick
    audio[:music] ||= { input: "sounds/music.mp3", looping: true }
  end

  def draw
    render_background
    outputs.sprites << [100, 420, 1082, 93, "sprites/gosu/logo.png" ]
    outputs.labels << [520, 400, "By Tyler and Will", 5]
    outputs.labels << [500, 140, "Click anywhere to play", 4]
  end

  def handle_input
    state.screen = Level.new if inputs.mouse.click
  end

  def render_background
    path = 'sprites/gosu/background/colored_grass.png'
    outputs.sprites << scrolling_background(state.tick_count, path, 1.0)
  end

  def scrolling_background(at, path, rate, y = -100)
    image_x = 1024
    [
      { x: 0 - at.*(rate) % image_x, y: y, w: image_x, h: image_x, path: path },
      { x: image_x - at.*(rate) % image_x, y: y, w: image_x, h: image_x, path: path }
    ]
  end
end
