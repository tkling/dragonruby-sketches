# frozen_string_literal: true

class Constants
  def self.gosu_sprite_root
    "sprites/gosu"
  end

  def self.gosu_sprite(ending, w:, h:)
    {
      x: 0,
      y: 0,
      w: w,
      h: h,
      path: "#{gosu_sprite_root}/#{ending}"
    }
  end
end
