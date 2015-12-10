require_relative "../board"

# This is a board with octagonal cells, making only four neighbors
# This is aligned on the flat edges making a + form
class FlatOctagonalBoard < Board
	def stitching(x, y)
		# Returns neighbors left and above
		return [:normal, [
			([x - 1, y]     if x > 0),
			([x,     y - 1] if y > 0),
		].compact]
	end

	def type
		return "octagon-flat"
	end
end

# This version is joined on the angled portion making a x form
class StaggeredOctagonalBoard < Board
	def short_on
		@short_on || :odds
	end

	def short_on=(which)
		# Expects :odds or :evens
		@short_on = which
	end

	def is_short(y)
		short_on == :odds ? y % 2 : (y % 2 ? 0 : 1)
	end

	def stitching(x, y)
		return [:normal, y > 0  ? (is_short(y) ? [
			# Short rows always have 2 neighbors
			[x - 1, y - 1],
			[x + 1, y - 1]
		] : [
			# Long rows miss one on edges
			([x - 1, y - 1] if x > 0),
			([x + 1, y - 1] if x < width - 2)
		].compact) : []]
	end

	def coordinates
		for y in 0..(@field_height - 1)
			# Short rows have one less
			short = is_short(y)
			for x in 0..(@field_width - (short ? 2 : 1))
				# There are twice as many x positions but they're kind of half positions
				enum.yield [short + x * 2, y]
			end
		end
	end

	def type
		return "octagon-staggered"
	end

	def width
		return @field_width * 2
	end
end

# This version includes the small rhombi as cells.
class FullFlatOctagonalBoard < Board
	def stitching(x, y)
		# Returns neighbors left and above
		octagon = !(y & 1) # Odd is rhombus
		return [:normal, [
			# These are octagons only octagons can touch
			([x - 1, y]     if octagon and x > 0),
			([x,     y - 2] if octagon and y > 1),
			# These are rhombi when this is an octagon
			# But these are octagons when this is a rhombus
			([x,     y - 1] if y > 0),
			([x + 1, y - 1] if y > 0 and x < @field_width - 1),
		].compact]
	end

	def coordinates
		for y in 0..(@field_height - 1)
			# Short rows have one less
			short = y & 1
			for x in 0..(@field_width - short)
				enum.yield [x, y]
			end
		end
	end

	def type
		return "octagon-full-flat"
	end
end

# This version includes the small squares as cells.
class FullStaggeredOctagonalBoard < Board
	def stitching(x, y)
		# Squares are positioned on odd x's of even y's and on even x's of odd y's.
		octagon = !((y ^ x) & 1)
		return [:normal, [
			([x - 1, y]     if x > 0),
			([x - 1, y - 1] if octagon and y > 0 and x > 0),
			([x,     y - 1] if y > 0),
			([x + 1, y - 1] if octagon and y > 0 and x < @field_width - 1),
		].compact]
	end

	def type
		return "octagon-full-staggered"
	end
end