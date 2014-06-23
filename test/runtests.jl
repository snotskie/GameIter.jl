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
	# score, flags, and player are demanded by GameIter algorithms
	# here, score is either 0, meaning game still going
	# or 1, meaning someone just won
	# board is invisble to the GameIter algorithms and is only used here for logic
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
			f = Symbol[]
			p = prev.player===PLAYER_X? PLAYER_O : PLAYER_X
			b = copy(prev.board)
			b[x, y] = prev.player
			m = b .== prev.player
			for i in 1:3
				if all(m[1:end, i:i]) || all(m[i:i, 1:end])
					s = 1
				end
			end

			if all([m[i,i] for i in 1:3]) || all([m[1,3], m[2,2], m[3,1]])
				s = 1
			end

			if s == 1 || all(b .!= SQUARE_N)
				f = [FLAG_TERMINAL]
				p = prev.player
			end

			return new(s, f, p, b)
		else
			return new(0, [FLAG_ILLEGAL], PLAYER_X, fill(SQUARE_N, (3,3)))
		end
	end
end

# options required by GameIter algorithms
# options returns a tuple based on N, so for loops can "cycle through" options
import GameIter: options
options(curr::TTTState, N::Int) = (N%3+1, fld(N,3)%3+1)

for fn in [minimax, x->minimax_depth(x,uint(6)), minimax_prune, x->minimax_prune_depth(x,uint(6))]
	println("$fn")
	state = TTTState()
	println(state.board)
	println()
	@time while !(FLAG_TERMINAL in state.flags)
		@assert !(FLAG_ILLEGAL in state.flags)
		state = fn(state)
		@assert state !== nothing
		gc()
		println(state.board)
		println()
	end
	@assert state.score == 0
	println("===")
	println()
end