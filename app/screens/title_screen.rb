# frozen_string_literal: true

class TitleScreen < Screen
  attr_accessor :bg_image

  def initialize
    @permamuted = true
    @bg_image = {
      w: 1024,
      h: 1024,
      path: "sprites/gosu/background/colored_grass.png"
    }
  end

  def tick
    return if @permamuted
    audio[:music] ||= {input: "sounds/music.mp3", looping: true}
  end

  def draw
    outputs.sprites << scrolling_background(1.0)
    outputs.sprites << [100, 420, 1082, 93, "sprites/gosu/logo.png"]
    outputs.labels << [520, 400, "By Tyler and Will", 5]
    outputs.labels << [500, 140, "Click anywhere to play", 4]
  end

  def handle_input
    state.screen = Level.new if inputs.mouse.click
  end

  def scrolling_background(rate, y = -100)
    w = bg_image[:w]
    [0, w, w * 2].map do |x|
      {
        x: x - state.tick_count.*(rate) % w,
        y: y,
        w: w,
        **bg_image.slice(:h, :path)
      }
    end
  end
end
