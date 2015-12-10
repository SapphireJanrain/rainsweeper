#!/usr/bin/env ruby
# encoding: utf-8

require 'tk'
require 'optparse'
require_relative 'lib/board'
require_relative 'lib/timer'
require_relative 'lib/scores'

# Tkinter edition
# Only supports square mode

class GameWindow
	def initialize(root, options)
		@root, @prev_name = root, ""

		# Make widget pane
		@upper_frame = TkFrame.new(@root) {
			padx 5
			pady 5
			grid('row'=>0, 'column'=>0)
		}

		@timetext = TkVariable.new
		@timetext.value = "00:00"
		time = TkLabel.new(@upper_frame) {
			relief "sunken"
			borderwidth 2
			background "gray"
			foreground "green"
			padx 5
			pady 3
			grid('row'=>0, 'column'=>0)
		}
		time["textvariable"] = @timetext

		@restart = TkButton.new(@upper_frame) {
			relief "raised"
			borderwidth 2
			background "gray"
			text "R"
			grid('row'=>0, 'column'=>1)
			font "TkFixedFont"
		}
		@restart["command"] = proc {restart_game}


		@minestext = TkVariable.new
		@minestext.value = "000"
		mines = TkLabel.new(@upper_frame) {
			relief "sunken"
			borderwidth 2
			background "gray"
			foreground "green"
			padx 5
			pady 3
			grid('row'=>0, 'column'=>2)
		}
		mines["textvariable"] = @minestext

		# Make game pane
		@lower_frame = nil
		@cell = {}
		@board = Board.new(do_create: false, **options)
		@timer = Timer.new(proc {|*t| update_time(*t)}, timer: @board, start: true)
		create_tiles()
	end

	def create_tiles()
		@lower_frame.destroy if @lower_frame
		@lower_frame = TkFrame.new(@root) {
			padx 5
			pady 5
			grid('row'=>1, 'column'=>0)
		}

		for y in 0..(@board.height - 1)
			for x in 0..(@board.width - 1)
				@cell[[x, y]] = TkButton.new(@lower_frame) {
					relief "raised"
					borderwidth 2
					background "gray"
					disabledforeground "black"
					grid('row'=>y, 'column'=>x)

					font "TkFixedFont"
					text " "
				}
				@cell[[x, y]]["command"] = uncover(x, y)
				@cell[[x, y]].bind("ButtonRelease-3", mark(x, y))
			end
		end
	end

	def uncover(x, y)
		return proc {
			return if not @board.created? 

			mine, cells_uncovered = @board.uncover(x, y)
			cells_uncovered.each {|x, y| update_button(x, y) }

			end_game() if mine
			win_game() if @board.field_cleared?
		}
	end

	def mark(x, y)
		return proc {
			return if not @board.created?

			if @board.mark(x, y)
				update_mines()
				update_button(x, y)
			end
		}
	end

	def raise_button(button)
		button.configure(
			"state" => "normal",
			"relief" => "raised",
			"background" => "gray",
			"text" => " "
		)
	end

	def depress_button(button)
		button.configure(
			"state" => "disabled",
			"relief" => "flat"
		)
	end

	def update_button(x, y)
		text, button = @board.display_token(x, y), @cell[[x, y]]
		case text
		when :normal
			text = " "
		when :flagged
			text = "⚑"
		when :questionable
			text = "?"
		when :mine
			text = "✸"
			depress_button(button)
			button.configure("background" => "red")
		else
			text = text == "0" ? " " : text.to_s
			depress_button(button)
		end
		button.configure("text" => text)
	end

	def update_mines()
		@minestext.value = "%03i" % @board.mines_remaining
	end

	def update_time(*time)
		@timetext.value = "%02i:%02i" % time
	end

	def restart_game(rebuild = false)
		@restart["text"] = "R"
		@board.create()
		create_tiles() if rebuild
		
		for y in 0..(@board.height - 1)
			for x in 0..(@board.width - 1)
				raise_button(@cell[[x, y]])
			end
		end

		@timer.reset.run()
		update_time(0, 0)
		update_mines()
	end

	def restart_to_mode(mode, custom = nil)
		case mode
		when :beginner
			custom = {width: 9, height: 9, mines: 10}
		when :intermediate
			custom = {width: 16, height: 16, mines: 40}
		when :difficult
			custom = {width: 30, height: 16, mines: 99}
		else
			if custom.nil?
				puts "ERROR: Attempted to restart to unknown mode."
				return
			end
		end

		changed = custom[:width] != @board.width || custom[:height] != @board.height
		@board.set_dimensions(custom[:width], custom[:height])
		@board.set_mines(custom[:mines])
		restart_game(changed)

		$scores.set_mode(["square", custom[:width], custom[:height], custom[:mines]])
	end

	def win_game()
		@restart["text"] = "\\o/"
		@timer.pause()

		score = @timer.seconds
		if $scores.in_top(score)
			dlg = TkToplevel.new($root) {
				title "High score! Enter your name"
			}

			# Player name entry
			player_name = TkVariable.new(@prev_name)
			TkEntry.new(dlg) {
				pack('side'=>"top")
			}.textvariable = player_name

			TkButton.new(dlg) {
				text "OK"
				pack('side'=>"bottom")
			}["command"] = proc {
				# Save score and close dialog
				@prev_name = player_name.to_s
				$scores.add_score(@prev_name, score)
				$scores.save()
				dlg.destroy()
			}
		end
	end

	def end_game()
		@restart["text"] = "!"
		@timer.pause()
	end
end

options = {
	mines:  30,
	width:  20,
	height: 20
}

opts = OptionParser.new do |opts|
	opts.banner = "Usage: tkinter.rb [options]"

	opts.on("-h", "--help", "Print this help") do |n|
		puts opts
		exit
	end

	opts.on("-m MINES", "--mines MINES", "Number of mines (default: 30)") do |n|
		options[:mines] = n.to_i
	end

	opts.on("-w WIDTH", "--width WIDTH", "Width of field (default: 20)") do |n|
		options[:width] = n.to_i
	end

	opts.on("-h HEIGHT", "--height HEIGHT", "Height of field (default: 20)") do |n|
		options[:height] = n.to_i
	end
end.parse!(ARGV)

$root = TkRoot.new { title "Rainsweeper!" }
game = GameWindow.new($root, options)
$scores = Scores.new("scores.dat", "tkinter", ["square", options[:width], options[:height], options[:mines]])

# Create menu panel
menubar = TkMenu.new($root)
$root.menu(menubar)

# Add menu items
# + Game      + Difficulty
# |- Restart  |- Beginner
# |- Scores   |- Intermediate
# |- Quit     |- Difficult
#             |---
#             |- Custom
mb_game = TkMenu.new(menubar) { tearoff false }
mb_game.add 'command', 'label' => 'Restart', 'command' => proc { game.restart_game }
mb_game.add 'command', 'label' => 'Scores', 'command' => proc {
	dlg = TkToplevel.new($root)

	$scores.read

	# Determine mode name
	board_type, width, height, mines = $scores.get_mode()
	mode_name = "Custom (%ix%i;%i)" % [width, height, mines] 
	if width == 9 && height == 9 && mines == 10
		mode_name = "Beginner"
	elsif width == 16 && height == 16 && mines == 40
		mode_name = "Intermediate"
	elsif width == 30 && height == 16 && mines == 99
		mode_name = "Difficult"
	end

	dlg["title"] = "Scores for %s Mode" % mode_name

	i = 0
	for score in $scores.top_scores
		TkLabel.new(dlg) {
			padx 5
			pady 3
			grid('row'=>i, 'column'=>0)
		}["text"] = score[:scorer]
		TkLabel.new(dlg) {
			padx 5
			pady 3
			grid('row'=>i, 'column'=>1)
		}["text"] = "%i secs" % score[:seconds]

		i += 1
	end

	lower = TkButton.new(dlg) {
		text "Close"
		grid('row'=>i, 'column'=>0, 'columnspan'=>2)
	}["command"] = proc {
		# Close dialog
		dlg.destroy()
	}
}
mb_game.add 'command', 'label' => 'Quit', 'command' => proc { exit 0 }
menubar.add 'cascade', 'menu'  => mb_game, 'label' => "Game"

diff = TkMenu.new(menubar) { tearoff false }
diff.add 'command', 'label' => 'Beginner', 'command' => proc { game.restart_to_mode(:beginner) }
diff.add 'command', 'label' => 'Intermediate', 'command' => proc { game.restart_to_mode(:intermediate) }
diff.add 'command', 'label' => 'Difficult', 'command' => proc { game.restart_to_mode(:difficult) }
diff.add 'separator'
diff.add 'command', 'label' => 'Custom', 'command' => proc {
	dlg = TkToplevel.new($root) {
		title "Custom Field"
	}

	TkLabel.new(dlg) {
		text "Width: "
		padx 5
		pady 3
		grid('row'=>0, 'column'=>0)
	}
	width = TkVariable.new(options[:width].to_s)
	TkEntry.new(dlg) {
		grid('row'=>0, 'column'=>1)
	}.textvariable = width

	TkLabel.new(dlg) {
		text "Height: "
		padx 5
		pady 3
		grid('row'=>1, 'column'=>0)
	}
	height = TkVariable.new(options[:height].to_s)
	TkEntry.new(dlg) {
		grid('row'=>1, 'column'=>1)
	}.textvariable = height

	TkLabel.new(dlg) {
		text "Mines: "
		padx 5
		pady 3
		grid('row'=>2, 'column'=>0)
	}
	mines = TkVariable.new(options[:mines].to_s)
	TkEntry.new(dlg) {
		grid('row'=>2, 'column'=>1)
	}.textvariable = mines

	lower = TkFrame.new(dlg) {
		grid('row'=>3, 'column'=>0, 'columnspan'=>2)
	}

	TkButton.new(lower) {
		text "Start"
		pack('side'=>"right")
	}["command"] = proc {
		# Save to options
		options[:width] = width.to_i
		options[:height] = height.to_i
		options[:mines] = mines.to_i

		# Restart game with new settings
		game.restart_to_mode(:custom, options)

		# Then close dialog
		dlg.destroy()
	}

	TkButton.new(lower) {
		text "Cancel"
		pack('side'=>"right")
	}["command"] = proc {
		# Close dialog without saving
		dlg.destroy()
	}
}
menubar.add 'cascade', 'menu'  => diff, 'label' => "Difficulty"

Tk.mainloop