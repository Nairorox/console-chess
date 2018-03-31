class Field
	attr_accessor :x_pos, :y_pos, :color, :look, :occupied_by
	@@count = 0
	@@reversed_color = false
	def initialize()
		if(@@count % 8 == 0)
			@@reversed_color = !@@reversed_color
		end
		@x_pos = @@count%8
		@y_pos = @@count / 8
		@occupied_by = nil
		@color = @@reversed_color ? "■" : "□"
		@look = @color
		@@reversed_color = !@@reversed_color
		@@count += 1
	end

	def display
		if(!@occupied_by.nil?)
			return occupied_by.look
		else
			return @look
		end
	end

end