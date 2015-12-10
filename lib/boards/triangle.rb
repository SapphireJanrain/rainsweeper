require_relative "../board"

#      _
#    /\ /\
#   /_\/_\
#  /\ /\ /\
# /_\/_\/_\
# \ /\ /\ /
# \/_\/_\/

# This is a board with triangular cells, making 1 neighbor on each side
# and 3 more on each point for a total of 12 neighbors.
class FlatOctagonalBoard < Board
	def stitching(x, y)
		# If upright: Returns 3 neighbors above and 2 left
		# Else: Returns 5 neighbors above and 2 left

		# 0,0 is upright so even rows have even cells as upright and odd rows have odd cells as upright.
		upright =  y & 1 == x & 1
		return [:normal, [
			([x - 2, y - 1] if x > 1 and y > 0 and upright),
			([x - 1, y - 1] if x > 0 and y > 0),
			([x,     y - 1] if y > 0),
			([x + 1, y - 1] if y > 0 and x < @field_width - 1),
			([x + 2, y - 1] if y > 0 and upright and x < @field_width - 2),
			([x - 2, y]     if x > 1),
			([x - 1, y]     if x > 0),
		].compact]
	end

	def type
		return "triangle"
	end
end
