# Manage scores file

require 'set'
require_relative "./exception"

class Scores
	def initialize(scores_file, game_name, mode = nil)
		@scores_file, @game_name, @scores, @read_in = scores_file, game_name, {}, false
		set_mode(mode) if not mode.nil?
		begin
			read()
		rescue Errno::ENOENT => e
			# Do nothing
		end
	end

	def read(clear = false)
		# fmt
		# char[4] "MSSF"
		# ushort  version
		begin
			bin = File.binread(@scores_file)
		rescue Errno::ENOENT
			puts "Warning: Tried to read scores file \"%s\" but it did not exist. No scores loaded." % @scores_file
			@scores = {} if clear
			return
		end

		magic, version = bin.unpack("a4S")
		if magic != "MSSF"
			throw SweeperDevError, "Not a scores file: " + @scores_file
		end

		@scores = {} if clear

		case version
		when 1
			read_1(bin)
		end

		@read_in = true
	end

	def read_1(bin)
		# fmt:
		# ulong   game_header_loc
		# game_header
		#     ushort  num_games
		#     (char[*] game_name
		#     ulong   game_mode_loc)*
		# game_mode_headers
		#     ushort  num_modes
		#     (char[*] board_type
		#     ushort  width/cols
		#     ushort  height/rows
		#     ushort  mines
		#     ulong   scores_loc)*
		# score_entries
		#     ushort  num_scores
		#     (ushort score_id
		#     char[*] name
		#     ulong   seconds)*

		# Retrieve game_headers
		game_header_loc = bin.unpack("@6L")[0]
		num_games = bin.unpack("@%iS" % game_header_loc)[0]
		gh_offset = game_header_loc + 2

		for g in 1..num_games
			name, modes_loc = bin.unpack("@%iZ*L" % gh_offset)
			# Add game
			@scores[name] = {} if @scores[name].nil?
			scores = @scores[name]

			num_modes = bin.unpack("@%iS" % modes_loc)[0]
			mh_offset = modes_loc + 2
			for m in 1..num_modes
				board_type, width, height, mines, scores_loc = bin.unpack("@%iZ*SSSL" % mh_offset)
				# Add mode to game
				mode = [board_type, width, height, mines]
				scores[mode] = [] if scores[mode].nil?

				num_scores = bin.unpack("@%iS" % scores_loc)[0]
				sh_offset = scores_loc + 2
				for s in 1..num_scores
					# Add score to mode
					sid, scorer, secs = bin.unpack("@%iSZ*L" % sh_offset)
					scores[mode] |= [{
						id: sid,
						scorer: scorer,
						seconds: secs
					}]

					sh_offset += scorer.length + 7
				end

				mh_offset += board_type.length + 11
			end

			gh_offset += name.length + 5
		end
	end

	def write(version = 1)
		bin = ["MSSF", version].pack("a4S")
		case version
		when 1
			bin = write_1(bin)
		end

		# Write the file out
		File.binwrite(@scores_file, bin)
	end

	def write_1(bin)
		# See read_1 for format
		bin += [bin.length + 4].pack("L")

		# Begin game header
		bin += [@scores.length].pack("S")

		# Need to get the total size of the game header section
		offset = bin.length
		for game_name, game in @scores
			offset += game_name.length + 5
		end

		# Write each game header
		game_bin = ""
		for game_name, game in @scores
			bin += [game_name, offset].pack("Z*L")

			game_bin += [game.length].pack("S")
			offset += 2

			score_bin, offsets = "", {}
			for mode, scores in game
				# Write each score header
				offsets[mode] = score_bin.length
				score_bin += [scores.length].pack("S")
				for score in scores
					score_bin += [score[:id], score[:scorer], score[:seconds]].pack("SZ*L")
				end

				# Sum up for start of scores headers for this game
				offset += mode[0].length + 11
			end

			# Write modes headers for this game
			for mode, scores in game
				game_bin += (mode + [offset + offsets[mode]]).pack("Z*SSSL")
			end

			# All modes headers written, write scores headers
			game_bin += score_bin

			offset += score_bin.length
		end

		# Commit the mode and score data and write it out
		return bin + game_bin
	end

	def save(version = 1)
		# Loads latest scores from the file before writing out the contents
		# This does not overwrite any scores added
		read()
		write(version)
	end

	### Functions to manage scores ###
	def set_mode(mode)
		begin
			@mode = [mode.type, mode.width, mode.height, mode.mines]
		rescue NoMethodError
			@mode = mode
		end
		@scores[@game_name] = {} if @scores[@game_name].nil?
		@scores[@game_name][@mode] = [] if @scores[@game_name][mode].nil?
	end

	def get_mode()
		@mode
	end

	def add_score(player, seconds)
		@scores[@game_name][@mode].push({
			# 0b1RRR 0xRLL or 0b0RRR 0xRRR; R = random, L = length of score list
			id: (rand(0x7F) << 8) | (@read_in ? 0x8000 | @scores[@game_name][@mode].length : rand(0x00FF)),
			scorer: player,
			seconds: seconds
		})
	end

	def clear_scores(version = 1)
		read()
		@scores[@game_name][@mode] = []
		write(version)
	end

	def clear_game_scores(version = 1)
		read()
		@scores[@game_name] = {}
		write(version)
	end

	def top_scores(top = 5)
		# Sort the scores (lowest first)
		scores = @scores[@game_name][@mode]
		scores.sort! { |a, b| a[:seconds] <=> b[:seconds] }
		return scores[0,5]
	end

	def in_top(score, top = 5)
		# Checks if the score is within the top X scores
		tops = top_scores(top)
		return tops.length < top || score < tops[-1][:seconds]
	end
end
