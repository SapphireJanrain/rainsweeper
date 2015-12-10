class SuperBoard < Board
	def coordinates
		Enumerator.new do |enum|
			y_end = @field_height - 1
			x_end = @field_width - 1
			for cylinder_y in 0..y_end
				for cylinder_x in 0..x_end
					# Contents of the cylinder.
					for y in 0..6
						for x in [0..2, 0..4, 0..1, 0..4, 0..1, 0..4, 0..2][y]
							enum.yield [cylinder_x, cylinder_y, x, y]
						end
					end

					# If there's another cylinder after this one...
					if cylinder_x < x_end
						# ...horziontally,
						enum.yield [cylinder_x + 0.5, cylinder_y - 0.5, 0.5, 1]
						enum.yield [cylinder_x + 0.5, cylinder_y + 0.5, 0.5, 0]
					end
					if cylinder_y < y_end
						# ...vertically,
						enum.yield [cylinder_x - 0.5, cylinder_y + 0.5, 0, 0.5]
						enum.yield [cylinder_x + 0.5, cylinder_y + 0.5, 1, 0.5]
					end
				end
			end
		end
	end

	def stitching(cylinder_x, cylinder_y, x, y)
		return [:normal, (cylinder_x.floor == cylinder_x ? {
			# Inside a cylinder.
			[0, 0] => [
				([cylinder_x - 0.5, cylinder_y - 0.5, 0.5, 1] if cylinder_x > 0),
				([cylinder_x - 0.5, cylinder_y - 0.5, 1, 0.5] if cylinder_y > 0),
				([cylinder_x, cylinder_y - 1, 0, 6] if cylinder_y > 0),
				([cylinder_x, cylinder_y - 1, 1, 6] if cylinder_y > 0),
			].compact,
			[1, 0] => [[0, 0],
				([cylinder_x, cylinder_y - 1, 0, 6] if cylinder_y > 0),
				([cylinder_x, cylinder_y - 1, 1, 6] if cylinder_y > 0),
				([cylinder_x, cylinder_y - 1, 2, 6] if cylinder_y > 0),
			].compact,
			[2, 0] => [[1, 0],
				([cylinder_x, cylinder_y - 1, 1, 6] if cylinder_y > 0),
				([cylinder_x, cylinder_y - 1, 2, 6] if cylinder_y > 0),
				([cylinder_x + 0.5, cylinder_y - 0.5, 0, 0.5] if cylinder_x > 0 and cylinder_y > 0),
			].compact,

			[0, 1] => [[0, 0],
				([cylinder_x - 0.5, cylinder_y - 0.5, 0.5, 1] if cylinder_x > 0),
				([cylinder_x - 0.5, cylinder_y - 0.5, 1, 0.5] if cylinder_y > 0),
				([cylinder_x - 1, cylinder_y, 4, 1] if cylinder_x > 0),
				([cylinder_x - 1, cylinder_y, 4, 3] if cylinder_x > 0),
			].compact,
			[1, 1] => [[0, 0], [1, 0], [0, 1],
				([cylinder_x - 0.5, cylinder_y - 0.5, 0.5, 1] if cylinder_x > 0),
				([cylinder_x - 0.5, cylinder_y - 0.5, 1, 0.5] if cylinder_y > 0),
			].compact,
			[2, 1] => [[0, 0], [1, 0], [2, 0], [1, 1]],
			[3, 1] => [[1, 0], [2, 0], [2, 1]],
			[4, 1] => [[2, 0], [3, 1]],

			[0, 2] => [[1, 1], [2, 1]],
			[1, 2] => [[2, 1], [3, 1], [0, 2]],

			[0, 3] => [[0, 1], [1, 1],
				([cylinder_x - 1, cylinder_y, 4, 1] if cylinder_x > 0),
				([cylinder_x - 1, cylinder_y, 4, 3] if cylinder_x > 0),
				([cylinder_x - 1, cylinder_y, 4, 5] if cylinder_x > 0),
			].compact,
			[1, 3] => [[0, 1], [1, 1], [2, 1], [0, 2], [0, 3]]
			[2, 3] => [[0, 2], [1, 2]],
			[3, 3] => [[2, 1], [3, 1], [4, 1], [1, 2]],
			[4, 3] => [[3, 1], [4, 1], [3, 3]],

			[0, 4] => [[0, 2], [1, 3], [2, 3]],
			[1, 4] => [[1, 2], [2, 3], [3, 3], [0, 4]],

			[0, 5] => [[0, 3], [1, 3],
				([cylinder_x - 0.5, cylinder_y + 0.5, 0.5, 1] if cylinder_x > 0),
				([cylinder_x - 1, cylinder_y, 4, 3] if cylinder_x > 0),
				([cylinder_x - 1, cylinder_y, 4, 5] if cylinder_x > 0),
			].compact,
			[1, 5] => [[0, 3], [1, 3], [0, 4], [0, 5],
				([cylinder_x - 0.5, cylinder_y + 0.5, 0.5, 1] if cylinder_x > 0),
			].compact,
			[2, 5] => [[1, 3], [3, 3], [0, 4], [1, 4], [1, 5]],
			[3, 5] => [[3, 3], [4, 3], [1, 4], [2, 5]],
			[4, 5] => [[3, 3], [4, 3], [3, 5]],

			[0, 6] => [[0, 5], [1, 5], [2, 5]],
			[1, 6] => [[1, 5], [2, 5], [3, 5], [0, 6]],
			[2, 6] => [[2, 5], [3, 5], [4, 5], [1, 6]],
		} : {
			# Between cylinders.
			[0.5, 0] => [
				([0, 0.5] if cylinder_y < @field_height - 1),
				([1, 0.5] if cylinder_y < @field_height - 1),
				[cylinder_x - 0.5, cylinder_y - 0.5, 3, 5],
				[cylinder_x - 0.5, cylinder_y - 0.5, 4, 5],
				[cylinder_x - 0.5, cylinder_y - 0.5, 2, 6],
			].compact,
			[0, 0.5] => [
				[cylinder_x - 0.5, cylinder_y - 0.5, 3, 5],
				[cylinder_x - 0.5, cylinder_y - 0.5, 4, 5],
				[cylinder_x - 0.5, cylinder_y - 0.5, 2, 6],
			],
			[1, 0.5] => [
				([0, 0.5] if cylinder_x > 0 and cylinder_y < @field_height - 1),
				[cylinder_x + 0.5, cylinder_y - 0.5, 0, 5],
				[cylinder_x + 0.5, cylinder_y - 0.5, 1, 5],
				[cylinder_x + 0.5, cylinder_y - 0.5, 0, 6],
			].compact,
			[0.5, 1] => [
				([0, 0.5] if cylinder_y > 0),
				([1, 0.5] if cylinder_y > 0),
				([0.5, 0] if cylinder_y > 0),
				[cylinder_x - 0.5, cylinder_y + 0.5, 2, 0],
				[cylinder_x - 0.5, cylinder_y + 0.5, 3, 1],
				[cylinder_x - 0.5, cylinder_y + 0.5, 4, 1],
			].compact,
		})[[x, y]].map{|x|
			x.length == 2 ? [cylinder_x, cylinder_y] + x : x
		}]
	end
end