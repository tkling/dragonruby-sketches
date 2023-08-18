# frozen_string_literal: true

require_relative 'screens/screen'
require_relative 'screens/title_screen'

def tick(args)
  screen = sync_screen(args)
  screen.tick
  screen.draw
  screen.handle_input

  handle_input(args)
end

def sync_screen(args)
  screen         = (args.state.screen ||= TitleScreen.new)
  screen._       = args
  screen.state   = args.state
  screen.outputs = args.outputs
  screen.audio   = args.audio
  screen.inputs  = args.inputs
  screen.grid    = args.grid
  screen.gtk     = args.gtk
  screen
end

def handle_input(args)
  args.gtk.request_quit if args.inputs.keyboard.key_down.escape
end
