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
  screen = sync_screen(args)
  screen.tick
  screen.draw

  handle_input(args)
end

def sync_screen(args)
  (args.state.screen ||= TitleScreen.new).tap do |screen|
    screen.sync!(args)
  end
end

def handle_input(args)
  args.gtk.request_quit if args.inputs.keyboard.key_down.escape
  args.state.screen.handle_input
end
