# frozen_string_literal: true

class Screen
  attr_accessor :_, :state, :outputs, :inputs, :grid, :gtk, :audio

  def draw
    nil
  end

  def tick
    nil
  end

  def handle_input
    nil
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
