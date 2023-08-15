# frozen_string_literal: true

class Level < Screen
  def draw
    outputs.labels << [640, 400, "Level 1 let's goooo", 5, 1]
  end
end
