using GameIter
using Base.Test

# Some helper constants
const PLAYER_X = :X
const PLAYER_O = :O
const SQUARE_X = :X
const SQUARE_O = :O
const SQUARE_N = :N
typealias TTTOptions (Int, Int)

# To use the GameIter algorithms, subclass AbstractGameState
# Semantically, this should also be an immutable type 
immutable TTTState <: AbstractGameState
	# score and flags are demanded by GameIter algorithms
	# here, score is either 0, meaning game still going
	# or -1, meaning someone just took a winning move and passed control
	# It's negative because score is assumed to be from the perspective of
	# the current player and, in TTT, control is passed as moves are made
	# player and board are invisble to the GameIter algorithms, only used here for logics
	score::Int
	flags::Array{Symbol,1}
	player::Symbol
	board::Array{Symbol,2}

	# TTTState() simply returns the initial state, and TTTState(prev, opts) is used by move.
	# This way, all the logic is kept in the internal constructors
	TTTState() = new(0, [], PLAYER_X, fill(SQUARE_N, (3,3)))
	function TTTState(prev::TTTState, opts::TTTOptions)
		x, y = opts
		if prev.board[x, y] === SQUARE_N
			s = 0
			f = {}
			p = prev.player===PLAYER_X? PLAYER_O : PLAYER_X
			b = copy(prev.board)
			b[x, y] = prev.player
			m = b .== prev.player
			for i in 1:3
				if all(m[1:end, i:i]) || all(m[i:i, 1:end])
					s = -1
				end
			end

			if all([m[i,i] for i in 1:3]) || all([m[1,3], m[2,2], m[3,1]])
				s = -1
			end

			if s == -1 || all(b .!= SQUARE_N)
				f = [FLAG_TERMINAL]
			end

			return new(s, f, p, b)
		else
			return new(0, [FLAG_ILLEGAL], PLAYER_X, fill(SQUARE_N, (3,3)))
		end
	end
end

# options and move by GameIter algorithms
# options returns a tuple based on N, so for loops can "cycle through" options
# move returns a state after prev where opts are taken
import GameIter: options, move
options(curr::TTTState, N::Int) = (N%3+1, fld(N,3)%3+1)
move(prev::TTTState, opts::TTTOptions) = TTTState(prev, opts)

for fn in [minimax_naive, minimax_prune]
	println("$fn")
	state = TTTState()
	println(state.board)
	while !(FLAG_TERMINAL in state.flags)
		@assert !(FLAG_ILLEGAL in state.flags)
		state = fn(state)
		@assert state !== nothing
		gc()
		println(state.board)
	end
	println("===")
end