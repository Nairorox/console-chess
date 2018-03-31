#~Damian Nowakowski

#TODO: game loop & inputs

#board[y][x].occupied_by is figure
#@players[0].figures[0] is first pawn
#@players[0].figures[8] is rook
#.move(x, y)

require "./classes/figures.rb"
require "./classes/gamefield.rb"
require "./classes/player.rb"

class Game
	attr_accessor :board, :last_moved_figure, :players
	def initialize

		@board = []
		@players = []
		@last_moved_figure = nil;
		create_board
		create_players
			#main loop comes here
			@players[0].every_check
			@players[0].checkmate_escape
			@board[1][3].occupied_by.move(3, 3)
			@players[1].figures[9].move(2, 5)
			display_board	
			#available to play through code so far
	end

	def game_over
		puts "The game is over"
	end

	private

	def create_board()
		8.times do |i|
			row_matrix = []
			8.times do  |j|
				row_matrix.push(Field.new())
			end
			@board.push(row_matrix)
		end
	end

	def display_board
		puts puts
		@board.each do |row|
			row.each do |field|
				print field.display
			end
			puts ""
		end

		#puts @board[1][0].occupied_by.move(5, 2)
	end

	def create_players
		@players.push(Player.new("white", 1, @board, true, self))
		@players.push(Player.new("black", 6, @board, false, self))
		@players[0].opponent = @players[1]
		@players[1].opponent = @players[0]
	end

	def random_move(player = @players[0])
		while (random_figure = player.figures[rand(player.figures.length)])
			available_moves = random_figure.every_available_move
			if(available_moves.length > 0)
				rand_move = available_moves[rand(available_moves.length)]
				random_figure.move(rand_move[0], rand_move[1])
				return
			end
		end
	end
end

game = Game.new
