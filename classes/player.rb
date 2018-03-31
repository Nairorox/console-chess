require "./classes/figures.rb"


class Player
	attr_accessor :king_checked, :king_checked_by, :opponent
	attr_reader :color, :figures, :board, :starts_top, :game, :every_possible_move, :king
	def initialize(color, row, board, starts_top, game)
		@figures = []
		@color = color
		@row = row
		@board = board
		@game = game
		@starts_top = starts_top
		@every_possible_move = []
		@king_checked_by = []
		@figures_with_available_moves = []
		@opponent = nil
		create_figures
	end

	def every_move
		every_possible = []
		@figures.each do |figure|
			if(figure)
				every_possible += (figure.show_possible_moves)
			end
		end
		#@every_possible.uniq!
		return every_possible
	end

		def checkmate_escape #checks if can escape checkmate
			possible_breaking_figures = @figures
			count = 0
			@king_checked_by.each do |checking_fig|
				possible_breaking_figures.each do |ally_fig|
					breaking = false
					ally_fig.show_possible_moves.each do |poss_move|
						if ally_fig.check_after_move(poss_move[0], poss_move[1], false)
							breaking = true
						end
					end
					if !breaking
						count += 1
						possible_breaking_figures.each do |br_fig|
							if br_fig == ally_fig
								ally_fig = nil
								possible_breaking_figures.compact!
							end
						end
					end
				end
				if count < @figures.length #available move
					print "escape possible"
					return true
				else #lose
					@game.game_over
				end
			end
			return false
		end

	def every_check
		@king_checked_by = [];
		@opponent.figures.each do |fig|
			if fig.show_possible_moves.include? [@king.at_field.x_pos, @king.at_field.y_pos]
				puts "#{opponent.color}'s king checked by #{fig.figure_name}"
				@king_checked_by.push(self)
			end
		end
	end

	private 
	def create_figures
		8.times do |j| #pawns
			@figures.push(@board[@row][j].occupied_by = Chess_figures::Pawn.new(self, @board[@row][j]))
		end
		if @row > 3
			@row += 1
		else 
			@row -= 1
		end #rest

		@figures.push(@board[@row][0].occupied_by = Chess_figures::Rook.new(self, @board[@row][0]))
		@figures.push(@board[@row][1].occupied_by = Chess_figures::Knight.new(self, @board[@row][1]))
		@figures.push(@board[@row][2].occupied_by = Chess_figures::Bishop.new(self, @board[@row][2]))
		@figures.push(@board[@row][3].occupied_by = Chess_figures::Queen.new(self, @board[@row][3]))
		@figures.push(@board[@row][4].occupied_by = Chess_figures::King.new(self, @board[@row][4]))
		@king = @board[@row][4].occupied_by
		@figures.push(@board[@row][5].occupied_by = Chess_figures::Bishop.new(self, @board[@row][5]))
		@figures.push(@board[@row][6].occupied_by = Chess_figures::Knight.new(self, @board[@row][6]))
		@figures.push(@board[@row][7].occupied_by = Chess_figures::Rook.new(self, @board[@row][7]))
	end

end