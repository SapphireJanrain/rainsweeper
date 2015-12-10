# Cell state and neighbors
class Cell
	def initialize(type, coords)
		@type, @coords= type, coords
		@neighbors = []
		@state = :normal
		@count = 0
	end

	def type
		return @type
	end

	def display_token
		if @state == :uncovered
			if @type == :normal
				return @count.to_s
			end
			return @type
		end
		return @state
	end
	
	def add_neighbor(cell)
		@neighbors.push(cell)
		if cell.type == :mine
			@count += 1
		end
	end

	def neighbors
		@neighbors
	end

	# Uncover cell, return [mine?, cells_uncovered]
	def uncover
		mine, uncovered = false, []
		if @state != :uncovered && @state != :flagged
			@state = :uncovered
			uncovered.push(@coords)
			mine = @type == :mine

			# Uncover neighbors
			if not mine and @count == 0
				@neighbors.each do |neighbor|
					# We can assume a neighbor is never a mine in this case
					uncovered += neighbor.uncover()[1]
				end
			end
		end
		return [mine, uncovered]
	end

	# Mark cell (with flag etc) Return true if state changed
	def mark(state = nil)
		old_state = @state
		if state.nil?
			case @state
			when :normal
				@state = :flagged
			when :flagged
				@state = :questionable
			when :questionable
				@state = :normal
			end
		elsif @state != :uncovered
			@state = state
		end
		
		if old_state == @state
			return nil
		else
			return [old_state, @state]
		end
	end
end