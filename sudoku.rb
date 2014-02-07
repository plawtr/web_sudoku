require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'

require_relative './lib/sudoku'
require_relative './lib/cell'
require_relative './helpers/application'

configure :production do
  require 'newrelic_rpm'
end

set :partial_template_engine, :erb
enable :sessions
set :session_secret, "Sudoku sucks!!!"

use Rack::Flash

def random_sudoku
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	sudoku.solve!
	sudoku.to_s.chars
end

def puzzle(sudoku)
	some_empties = sudoku.dup
	ddifficulty = @difficulty == 'high' ? 45 : 23 
	while some_empties.count("0")<ddifficulty  
		some_empties[rand(80)] = "0"
	end
	some_empties
end

def box_order_to_row_order(cells)
	boxes = cells.each_slice(9).to_a
	(0..8).to_a.inject([]){|memo, i| 
		first_box_index = i / 3 * 3
		three_boxes = boxes[first_box_index, 3]
		three_rows_of_three = three_boxes.map do |box|
			row_number_in_a_box = i % 3
			first_cell_in_the_row_index = row_number_in_a_box * 3
			box[first_cell_in_the_row_index, 3]
		end
		memo+= three_rows_of_three.flatten
	}
end

def prepare_to_check_solution
	@check_solution = session[:check_solution]
	if @check_solution 
		flash[:notice] = "Incorrect values are highlighted in yellow."
	end
	session[:check_solution] = nil
end

def generate_new_puzzle_if_necessary
	return if session[:current_solution]
	sudoku = random_sudoku
	session[:solution] = sudoku 
	session[:puzzle] = puzzle(sudoku)
	session[:current_solution] = session[:puzzle]
end

get '/' do
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	@current_solution = session[:current_solution] || session[:puzzle]
	@solution = session[:solution]
	@puzzle = session[:puzzle]	

	# puts @current_solution.inspect
	# puts @solution.inspect
	# puts @puzzle.inspect

	erb :index
end

post '/' do
	cells = params["cell"]
	session[:current_solution] = box_order_to_row_order(cells).map{|value| value.to_i}.join
	session[:check_solution] = !params["Save"]
	redirect to("/")
end

get '/solution' do
	@current_solution = session[:solution] 
	erb :index
end

post '/new-game' do
	puts params
	@difficulty = params[:difficulty]
	session[:current_solution] = nil
	redirect to("/")
end



