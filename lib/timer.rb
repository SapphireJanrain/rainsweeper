#!/usr/bin/env ruby
# encoding: utf-8

# This class runs a timer that calls the callback every second

class Timer
	def initialize(callback, mode = :count_up, from = 0, start: false, timer: nil)
		# The callback function should look like: def callback(mins, secs)
		# mode: :count_up or :count_down
		# from: starting time in seconds
		# start: whether or not to run right after creation
		# timer: use this timer to get the time instead
		#  it must define a function 'seconds' that returns the time in seconds
		@callback, @mode, @from, @time, @running, @timer = callback, mode, from, from, false, timer

		@thread = nil

		run if start
	end

	def reset(to = nil)
		@time = to.nil? ? @from : to
		return self
	end

	def run()
		if not @running
			@last_time = @timer.nil? ? Time.now.to_f : @timer.seconds
			@running = true

			if @thread.nil? or not @thread.alive?
				@thread = Thread.new do
					while true
						if not @running then
							Thread.stop
						end

						sleep(0.1)
						next_time = @timer.nil? ? Time.now.to_f : @timer.seconds
						diff_time = (next_time - @last_time).to_i

						if diff_time >= 1
							puts "WARNING: Missed %i seconds worth of callbacks." % (diff_time - 1) if diff_time >= 2

							@last_time += diff_time
							case @mode
							when :count_up
								@time += diff_time
							when :count_down
								@time -= diff_time
								if @time <= 0
									@time = 0
									pause()
								end
							end

							mins = (@time / 60).floor
							secs = @time - mins * 60
							Thread.new {
								begin
									@callback.call(mins, secs)
								rescue => detail
									puts "Exception in callback: " + detail.to_s
								end
							}
							Thread.pass
						end
					end
				end
			else
				@thread.run
			end
		end
	end

	def pause()
		@running = false
	end

	def resume()
		run
	end

	def flip()
		case @mode
		when :count_up
			@mode = :count_down
		when :count_down
			@mode = :count_up
		end
	end

	def up()
		@mode = :count_up
	end

	def down()
		@mode = :count_down
	end

	def up?
		@mode == :count_up
	end

	def down?
		@mode == :count_down
	end

	def running?
		@running && @thread.alive?
	end

	def seconds
		@time
	end
end
