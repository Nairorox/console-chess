module Chess_figures

	class Figure
		attr_accessor :figure_name, :look, :owned_by, :at_field, :times_moved, :starts_top_switch, :show_possible_moves
		@@white = {:pawn => "♙",:bishop => "♗",:king => "♔",:knight => "♘",:queen => "♕",:rook => "♖"}
		@@black = {:pawn => "♟",:bishop => "♝",:king => "♚",:knight => "♞",:queen => "♛",:rook => "♜"}

		def initialize(owned_by, parent_field)
			@at_field = parent_field
			@owned_by = owned_by
			@figure_name = self.class.name.split("::").last
			@game = owned_by.game
			@board = owned_by.board
			@set = owned_by.color == "white" ? @@white : @@black
			@times_moved = 0
			@starts_top_switch = -1
			if @owned_by.starts_top
				@starts_top_switch = 1
			end
		end

		def die
			self.owned_by.figures.each_with_index do |fig, i|
				if fig == self
					self.owned_by.figures[i] = nil
					self.owned_by.figures.compact!
				end
			end
			self.at_field.occupied_by = nil
			self.owned_by = nil
			self.at_field = nil
		end

		def every_available_move
			show_possible_moves.select do |move|
				check_after_move(move[0], move[1], false)
			end
		end


		def move(x, y)
			if(check_move(x, y) && check_after_move(x, y))
				@at_field.occupied_by = nil
				if(@board[y][x].occupied_by) #kills enemy figure
					@board[y][x].occupied_by.die()
				end
				@at_field = @board[y][x]
				@at_field.occupied_by = self
				@times_moved += 1;
				#promotion
				@game.last_moved_figure = self
				@en_passant_possible = false
				if(@figure_name == "Pawn") #checks promotion if pawn
					promotion_handler
				end
				return true
			else
				puts "Incorrect move"
				return false
			end
		end

		def check_after_move(x, y, notification = true) #disallows own tour checkmate
			init_pos = [@at_field.x_pos, @at_field.y_pos];
			figure_died = @board[y][x].occupied_by
			opponent = @owned_by.opponent

			if(@board[y][x].occupied_by)
				@board[y][x].occupied_by = nil
			end

			@board[y][x].occupied_by = self
			@board[init_pos[1]][init_pos[0]].occupied_by = nil

			#check
			king_pos = [@owned_by.king.at_field.x_pos,  @owned_by.king.at_field.y_pos]
			if (@figure_name == "King")
				king_pos = [x, y]
			end

			correct = true #needs optimization for randommove
			opponent.figures.each do |figure| 
				figure.show_possible_moves.each do |poss_move|
					if(king_pos[0] == poss_move[0] && king_pos[1] == poss_move[1])
						if(x != figure.at_field.x_pos || y != figure.at_field.y_pos)
							return  false
						end
					end
				end
			end

			#back to initial
			@board[init_pos[1]][init_pos[0]].occupied_by = self
			@board[y][x].occupied_by = figure_died

			if !correct && notification
				puts "Move would result in checkmate"
			end
			return correct
		end

		private

		def check_move(dest_x, dest_y)
			desired_move = [dest_x, dest_y]
			available_moves = show_possible_moves
			if @en_passant_possible && available_moves.last == desired_move
				@game.last_moved_figure.die
				return true
			else		
				available_moves.each do |move|
					if desired_move == move
					 	return true
					end
				end
			end	
			return false
		end

		def direction_moving_possibilities(dir_x, dir_y, arr )
			x = @at_field.x_pos + dir_x
			y = @at_field.y_pos + dir_y

				while (true)
					if(x < 0 || x > 7 || y < 0 || y > 7)
						return arr
					end
					if(check_capture(x, y))
						arr.push([x, y])
					end
					if @board[y][x].occupied_by
						return arr
					end
					x += dir_x
					y += dir_y
				end
		end

		def rook_moving
			rook_possible = []
			direction_moving_possibilities(0, 1, rook_possible)
			direction_moving_possibilities(1, 0, rook_possible)
			direction_moving_possibilities(0, -1, rook_possible)
			direction_moving_possibilities(-1, 0, rook_possible)
			return rook_possible
		end


		def cross_moving
			cross_moves = []
			direction_moving_possibilities(1, 1, cross_moves)
			direction_moving_possibilities(-1, -1, cross_moves)
			direction_moving_possibilities(-1, 1, cross_moves)
			direction_moving_possibilities(1, -1, cross_moves)
			return cross_moves
		end

		private
		def check_capture(x, y)
			if(@board[y][x].occupied_by)
				return !(@board[y][x].occupied_by.owned_by == @owned_by )
			end
			return true
		end
	end

	#specific figures

	class Pawn < Figure
		def initialize(owned_by, parent_field)
			super
			@look = @set[:pawn]
			@en_passant_possible = false
		end

		def show_possible_moves
			if(@promoted) #promotion case
				return rook_moving + cross_moving
			end #normal case
			xpos = @at_field.x_pos
			ypos = @at_field.y_pos
			possible_moves = []
			if  xpos > 0 && xpos < 7
				if !@board[ypos + 1 * @starts_top_switch][xpos - 1].occupied_by.nil?
					if check_capture(xpos-1, ypos + 1 * @starts_top_switch)
						possible_moves.push([xpos - 1, ypos + 1 * @starts_top_switch])
					end
				end
				if !@board[ypos + 1 * @starts_top_switch][xpos + 1].occupied_by.nil?
					if check_capture(xpos + 1, ypos + 1 * @starts_top_switch)
						possible_moves.push([xpos + 1, ypos + 1 * @starts_top_switch])
					end
				end
			end

			if @board[ypos + 1 * @starts_top_switch][xpos].occupied_by.nil?
				possible_moves.push([xpos, ypos + 1 * @starts_top_switch])
				if @times_moved == 0 && @board[ypos + 2 * @starts_top_switch][xpos].occupied_by.nil?
					possible_moves.push([xpos, ypos + 2 * @starts_top_switch])
				end
			end
			#en passant
			#last figure checks
			if !@game.last_moved_figure.nil? && !@game.last_moved_figure.at_field.nil?
				if @game.last_moved_figure.times_moved == 1 && (@game.last_moved_figure.at_field.y_pos == 3 || @game.last_moved_figure.at_field.y_pos == 4) 
					#position checks
					if (@game.last_moved_figure.at_field.x_pos - @at_field.x_pos).abs == 1 && @at_field.y_pos == @game.last_moved_figure.at_field.y_pos
						possible_moves.push([@game.last_moved_figure.at_field.x_pos, @game.last_moved_figure.at_field.y_pos + @starts_top_switch])
						@en_passant_possible = true
					end
				end
			end
			return possible_moves
		end

		private

		def promotion_handler
			if (@at_field.y_pos == 6 && @owned_by.starts_top ) || (!@owned_by.starts_top && @at_field.y_pos == 1)
				@look = @set[:queen]
				@promoted = true
			end
		end

	end

	class Bishop < Figure
		def initialize(owned_by, parent_field)
			super
			@look = @set[:bishop]
		end

		def show_possible_moves
			return cross_moving
		end

		private
	end

	class King < Figure
		def initialize(owned_by, parent_field)
			super
			@look = @set[:king]
		end

		def move(x, y)
			super
			x = @at_field.x_pos
			y = @at_field.y_pos

			if times_moved == 0
				if(x == 2 && @board[y][0].occupied_by.figure_name == "Rook") #castling
					puts "Castling"
					rook_copy = @board[y][0].occupied_by
					@board[y][0].occupied_by = nil
					@board[y][3].occupied_by = rook_copy
					rook_copy.at_field = @board[y][3]
				elsif(x == 6 && @board[y][7].occupied_by.figure_name == "Rook")
					puts "Castling"
					rook_copy = @board[y][7].occupied_by
					@board[y][7].occupied_by = nil
					@board[y][5].occupied_by = rook_copy
					rook_copy.at_field = @board[y][5]
				end
			end
		end


		def show_possible_moves

			x = @at_field.x_pos
			y = @at_field.y_pos

			possible_moves = []

			for i in y-1...y+2 do 
				for j in x-1...x+2 do
					if i >= 0 && i < 8 && j >= 0 && j < 8
						if(check_capture(j, i))
							possible_moves.push([j, i])
						end
					end 
				end
			end

			#moves + castling moves
			if castling_moves
				return possible_moves + castling_moves
			end
			return possible_moves		
		end


		def castling_moves #could be refactored
			cast_moves = []
			x = self.at_field.x_pos-1
			y = self.at_field.y_pos
			if(y == 0 || y == 7)
				good = true
				while x > 0
					if(!@board[y][0].occupied_by.nil?)
						if(@owned_by.king_checked_by.length > 0 || !@board[y][x].occupied_by.nil? || ((@owned_by.opponent.every_move.include? [x, y])) && x > x - 3)
							good = false
						end
					end
					x-= 1
				end
				if(!@board[y][0].occupied_by.nil?)
					if(!@board[y][0].occupied_by.nil? && good && !(@board[y][0].occupied_by.times_moved > 0) && @board[y][7].occupied_by.figure_name == "Rook")
						cast_moves.push([2, y])
					end
				end
				#to right side
				x = self.at_field.x_pos + 1
				good = true
				while x < 7
					if(!@board[y][7].occupied_by.nil?)
						if( @board[y][7].occupied_by.times_moved > 0 || @owned_by.king_checked_by.length > 0 || !@board[y][x].occupied_by.nil? || ((@owned_by.opponent.every_move.include? [x, y])) )
							good = false
						end
					end
					x+= 1
				end
				if(!@board[y][7].occupied_by.nil?)
					if(!@board[y][7].occupied_by.nil? && good && !(@board[y][7].occupied_by.times_moved > 0) && @board[y][7].occupied_by.figure_name == "Rook")
						cast_moves.push([6, y])
					end
				end
				return cast_moves
			end
		end
	end

	class Knight < Figure #to do moves
		def initialize(owned_by, parent_field)
			super
			@look = @set[:knight]
		end

		def show_possible_moves
			x =  self.at_field.x_pos
			y = self.at_field.y_pos

			possible_moves = []

				check_push(x, 1, y, -2, possible_moves)
				check_push(x, -1, y, -2, possible_moves)
				check_push(x, 1, y, 2, possible_moves)
				check_push(x, -1, y, 2, possible_moves)
				check_push(x, 2, y, 1, possible_moves)
				check_push(x, -2, y, 1, possible_moves)
				check_push(x, 2, y, -1, possible_moves)
				check_push(x, -2, y, -1, possible_moves)
			return possible_moves
		end

		private 

		def check_push(x, x_sign, y, y_sign, arr)
			if (x + x_sign >= 0 && x + x_sign < 8 && y+y_sign >= 0 && y+y_sign < 8)
				if @board[y + y_sign] && check_capture(x + x_sign, y + y_sign)
					arr.push([x + x_sign, y + y_sign])
				end
			end
		end

	end

	class Queen < Figure
		def initialize(owned_by, parent_field)
			super
			@look = @set[:queen]
		end

		def show_possible_moves
			return cross_moving + rook_moving
		end
	end

	class Rook < Figure
		def initialize(owned_by, parent_field)
			super
			@look = @set[:rook]
		end

		def show_possible_moves
			return rook_moving
		end
	end

end
