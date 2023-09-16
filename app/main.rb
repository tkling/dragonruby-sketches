# frozen_string_literal: true

requires = %w[
  lib/card
  lib/constants
  lib/player
  lib/ui
  screens/screen
  screens/title_screen
  screens/level
]

requires.each { |r| require_relative r }

def tick(args)
  screen = (args.state.screen ||= TitleScreen.new)
  screen.args = args
  screen.tick
  screen.draw

  handle_input(args)
end

def handle_input(args)
  args.gtk.request_quit if args.inputs.keyboard.key_down.escape
  args.state.screen = TitleScreen.new if args.keyboard.key_down.r
  args.state.screen.handle_input
end
