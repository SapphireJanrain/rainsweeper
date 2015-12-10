#!/usr/bin/env ruby
# encoding: utf-8

# Command Line edition
# Supports both square and octagon-flat styles of play

require 'readline'

require_relative './lib/board'
require_relative './lib/boards/octagon'
require_relative "./lib/exception"
require_relative "./lib/scores"

def cell_icon(board, x, y)
	token = board.display_token(x, y)
	case token
	when :normal
		if board.type == "octagon-flat"
			case [x, y]
			when [0, 0]
				return "┌"
			when [board.width - 1, 0]
				return "┐"
			when [0, board.height - 1]
				return "└"
			when [board.width - 1, board.height - 1]
				return "┘"
			else
				if x == 0
					return "├"
				elsif y == 0
					return "┬"
				elsif x == board.width - 1
					return "┤"
				elsif y == board.height - 1
					return "┴"
				else
					return "┼"
				end
			end
		else
			return "▯"
		end
	when :flagged
		return "⚑"
	when :questionable
		return "?"
	when :mine
		return "*"
	else
		return token.to_s
	end
end

$columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
def print_board(board)
	# Print time and mines remaining
	time = "%02i:%02i" % board.minsecs
	mines = "%03i" % board.mines_remaining
	puts(time + (" " * [board.width - time.length - mines.length + 1, 1].max) + mines)

	# Print column names (letters)
	spacer = board.height > 10
	line = spacer ? "  " : " "
	for x in 0..(board.width - 1)
		line += $columns[x]
	end
	puts(line)

	for y in 0..(board.height - 1)
		line = spacer && y < 10 ? " " + y.to_s : y.to_s
		for x in 0..(board.width - 1)
			line += cell_icon(board, x, y)
		end
		puts(line)
	end
end

def parse_loc(str)
	[$columns.index(str[0]), str.slice(1).to_i]
end

def request_cell(board, command = nil)
	ret = []
	loop do
		inp = command || Readline.readline("Enter command: ")

		case inp[0]
		when nil
			ret = [:nop]
		when "!"
			ret = [:flag] + parse_loc(inp[1..-1])
		when "?"
			ret = [:question] + parse_loc(inp[1..-1])
		when "."
			ret = [:unmark] + parse_loc(inp[1..-1])
		else
			cmd, *args = inp.downcase.split(" ")
			if ["h", "help"].include? cmd
				ret = [:help]
			elsif ["new", "reset", "restart"].include? cmd
				ret = [:new]
			elsif ["s", "score", "scores"].include? cmd
				ret = [:scores]
			elsif ["exit", "quit"].include? cmd
				ret = [:exit]
			elsif ["dif", "diff", "difficulty"].include? cmd
				case args[0]
				when *["b", "begin", "beginner", "e", "easy"]
					ret = [:diff, :beginner]
				when *["i", "inter", "intermediate", "m", "med", "medium"]
					ret = [:diff, :intermediate]
				when *["d", "dif", "diff", "difficult", "h", "hard"]
					ret = [:diff, :difficult]
				else
					ret = [nil]
				end
			elsif ["dim", "dims", "dimensions"].include? cmd
				cols, rows = args[0, 2]
				ret = [:dim, cols.to_i, rows.to_i]
			elsif ["mine", "mines"].include? cmd
				ret = [:mines, args[0].to_i]
			elsif ["sq", "square"].include? cmd
				ret = [:square]
			elsif ["oct", "octagon", "octagonal"].include? cmd
				ret = [:oct]
			elsif cmd == "uncover"
				ret = [:uncover] + parse_loc(args[0])
			elsif cmd == "flag"
				ret = [:flag] + parse_loc(args[0])
			elsif cmd == "question"
				ret = [:question] + parse_loc(args[0])
			else
				ret = [:uncover] + parse_loc(inp)
			end
		end

		break if not ret[0].nil? or (not ret[1].nil? and ret[1][0] < board.width and ret[1][1] < board.height)
	end
	return ret
end

def end_game(board)
	print_board(board)
	puts("You lose!")
end

$scores = Scores.new("scores.dat", "cli")
$board = Board.new(do_create: false)
$saved_name = ""
def run(argv = [])
	args = []
	argv.each do |a|
		if a[0, 2] == "--"
			args.push(a[2..-1])
		else
			args[-1] += " " + a
		end
	end

	print_next = true
	$board.create()
	$scores.set_mode($board)
	while not $board.field_cleared? do
		if print_next and args.length == 0
			print_board($board)
		end

		mode, x, y = request_cell($board, args.shift())

		case mode
		when :help
			puts("Commands:")
			puts(" help: Print this help message")
			puts(" new: Start a new game")
			puts(" exit: Exit game")
			puts(" diff DIFFICULTY: Set the difficulty to beginner, intermediate, or expert")
			puts(" dim COLS ROWS: Change the dimensions of the map. Must start a new game after")
			puts(" mines MINES: Change the mines on the map. Must start a new game after")
			puts(" square: Change the board to be square (8 neighboring cells)")
			puts(" oct: Change the board to be octagonal (4 neighboring cells)")
			puts("Coordinate commands (for X enter column letter, for Y enter the number):")
			puts(" XY: Uncover cell")
			puts(" !XY: Flag cell (you cannot uncover a cell while it's flagged)")
			puts(" ?XY: Question cell (you can uncover this cell but it looks distinct)")
			puts(" .XY: Unmark cell")
		when :new
			$board.create()
			$scores.set_mode($board)
		when :scores
			puts "Seconds | Name"
			$scores.read()
			for score in $scores.top_scores
				puts "%7i | %s" % [score[:seconds], score[:scorer]]
			end
		when :exit
			return
		when :diff
			case x
			when :beginner
				$board.set_dimensions(9, 9)
				$board.set_mines(10)
			when :intermediate
				$board.set_dimensions(16, 16)
				$board.set_mines(40)
			when :difficult
				$board.set_dimensions(30, 16)
				$board.set_mines(99)
			end
			$board.create()
			$scores.set_mode($board)
		when :dim
			$board.set_dimensions(x, y)
		when :mines
			$board.set_mines(x)
		when :square
			if $board.type != "square"
				$board = Board.new($board)
				$scores.set_mode($board)
			end
		when :oct
			if $board.type != "octagon-flat"
				$board = FlatOctagonalBoard.new($board)
				$scores.set_mode($board)
			end
		when :uncover
			if $board.uncover(x, y)[0]
				return end_game($board)
			end
			print_next = true
		when :unmark
			print_next = $board.mark(x, y, state: :normal)
		when :flag
			print_next = $board.mark(x, y, state: :flagged)
		when :question
			print_next = $board.mark(x, y, state: :questionable)
		end

		if $board.field_cleared?
			score = $board.seconds
			if $scores.in_top(score)
				def_name = ""
				if $saved_name
					def_name = " [#{$saved_name}]"
				end

				name = Readline.readline("You got a high score! Enter your name#{def_name}: ")
				while !name && !def_name
					name = Readline.readline("No, really, enter something: ")
				end
				$saved_name = name

				$scores.add_score(name, score)
				puts $scores.top_scores.to_s
				$scores.save()
				puts $scores.top_scores.to_s
			else
				puts("You win!")
			end
			return
		end
	end
end

begin
	loop do
		run(ARGV)
		if Readline.readline("Play again (y/n)? ").downcase != "y"
			break
		end
	end

rescue SweeperDevError => msg
	puts "Developer error: " + msg
rescue Interrupt
	puts "\nQuitting"
end
