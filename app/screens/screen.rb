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

  def sync!(args)
    self._ = args
    self.state = args.state
    self.outputs = args.outputs
    self.audio = args.audio
    self.inputs = args.inputs
    self.grid = args.grid
    self.gtk = args.gtk
  end

  def serialize
    {
      state: state.serialize,
      outputs: outputs.serialize,
      inputs: inputs.serialize,
      grid: grid.serialize,
      gtk: gtk.serialize,
      audio: audio.serialize
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end
