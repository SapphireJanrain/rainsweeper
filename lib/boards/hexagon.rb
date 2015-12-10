require_relative "../board"

class HexagonalBoard < Board
	def stitching(x, y)
		# Each even x is shifted down slightly and odd up.
		# So basically /\/\/\ etc.
		return [:normal, [
			([x - 1, y] if x > 0),
			([x - 1, y - 1] if x & 1 and y > 0 and x > 0),
			([x,     y - 1] if y > 0),
		].compact]
	end

	def type
		return "hexagon"
	end
end