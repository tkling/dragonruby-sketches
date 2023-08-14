# frozen_string_literal: true

require_relative 'level_1'

class TitleScreen < Screen
  def draw
    outputs.labels << [640, 400, "Spacebeing in a Spiky World", 5, 1]
    outputs.labels << [640, 40, "tick_count: #{state.tick_count}", 5, 1]
  end

  def handle_input
    state.screen = Level_1.new if inputs.mouse.click
  end
end
