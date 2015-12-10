require_relative './cell'
require_relative "./exception"

# Handles the board state including options and contents
class Board
	def initialize(old_board = nil, do_create: true, mines: 15, width: 10, height: 10)
		if old_board
			@starting_mines, @starting_width, @starting_height = old_board.transfer
		else
			@starting_mines = mines
			@starting_width = width
			@starting_height = height
		end
		
		@created = false

		if do_create
			create()
		end
	end

	def transfer
		[@starting_mines, @starting_width, @starting_height]
	end

	# The default stitching is a board of square tiles
	# Inherit & overwrite these as necessary
	def stitching(x, y)
		# Return only what's already been generated (that is, what's above and to the left).
		return [:normal, [
			([x - 1, y]     if x > 0),
			([x - 1, y - 1] if x > 0 and y > 0),
			([x,     y - 1] if y > 0),
			([x + 1, y - 1] if y > 0 and x < @field_width - 1)
		].compact]
	end

	def coordinates
		Enumerator.new do |enum|
			for y in 0..(@field_height - 1)
				for x in 0..(@field_width - 1)
					enum.yield [x, y]
				end
			end
		end
	end

	def length
		@field_width * @field_height
	end

	def type
		"square"
	end

	# Creation function
	def create()
		# stitiching is a function that
		#  takes x, y
		#  returns [type (if not mine), a list of already created neighbors [x,y]]
		# neighbors are created in LRUD form

		# Backup starting values to current field values
		@field_mines = @starting_mines
		@field_width = @starting_width
		@field_height = @starting_height
		@field_uncovered, @field_flagged = 0, 0
		@field_cells = {}

		# Generate mines
		mine_positions = []
		for i in 1..@field_mines
			rnd = rand(length) while rnd.nil? or mine_positions.include? rnd
			mine_positions.push(rnd)
		end
		mine_positions.sort!

		idx = 0
		for coords in coordinates
			# Mark if this is a mine and bump to the next mine position if so
			is_mine = idx == mine_positions[0]
			if is_mine then
				mine_positions.shift
			end

			# Stitch in the cell
			norm, neighbors = stitching(*coords)
			cell = Cell.new(is_mine ? :mine : norm, coords)
			@field_cells[coords] = cell

			# Set up neighbors
			neighbors.each do |neighbor|
				# Find existing neighbor
				target = @field_cells[neighbor]
				if target.nil?
					raise SweeperDevError, "Stitching for " + coords.to_s + " returned uncreated neighbor " + neighbor.to_s
				end

				# Add neighbor to new cell
				cell.add_neighbor(target)

				# Add this cell back
				target.add_neighbor(cell)
			end

			idx += 1
		end

		@field_time = Time.now.to_f
		@created = true

		return [@field_width, @field_height]
	end

	# In-game actions
	def uncover(*coords)
		return if not @created
		mine, cells_uncovered = @field_cells[coords].uncover
		@created = false if mine
		@field_uncovered += cells_uncovered.length
		return [mine, cells_uncovered]
	end

	def mark(*coords, state: nil)
		return if not @created
		m = @field_cells[coords].mark(state)
		return false if m.nil?

		if m[0] == :flagged
			@field_flagged -= 1
		elsif m[1] == :flagged
			@field_flagged += 1
		end
		return true
	end

	def display_token(*coords)
		return nil if @field_cells.nil?
		@field_cells[coords].display_token
	end

	def field_cleared?
		# This assumes no mines have been uncovered
		# It should not be called if uncover returns true
		@field_uncovered == @field_cells.length - @field_mines
	end

	# Information
	def created?
		@created
	end

	def width
		@field_width || @starting_width
	end

	def height
		@field_height || @starting_height
	end

	def mines
		@field_mines || @starting_mines
	end

	def mines_remaining
		@field_mines.nil? ? @starting_mines : @field_mines - @field_flagged
	end

	def seconds
		@field_time.nil? ? 0 : (Time.now.to_f - @field_time).to_i
	end

	def minsecs
		secs = seconds()
		[secs / 60, secs % 60]
	end

	# Settings
	def set_dimensions(cols, rows)
		@starting_width = cols if not cols.nil?
		@starting_height = rows if not rows.nil?
	end

	def set_mines(mines)
		@starting_mines = mines
	end
end