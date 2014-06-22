# GameIter

[![Build Status](https://travis-ci.org/snotskie/GameIter.jl.svg)](https://travis-ci.org/snotskie/GameIter.jl)

GameIter.jl provides a simple framework based on Julia's Iterator API and inspired by ValueDispatch.jl.

## Getting Started
```julia
# Step One: install and use GameIter
Pkg.clone("https://github.com/snotskie/GameIter.jl")
using GameIter

# Step Two: declare game state type
# Note:     score, flags, and player are required fields
#           score can be any numeric type and is always assuming
#           that the player denoted by the player field is trying to maximize this score.
#           flags is an array of Symbols, and player is a Symbol denoting the
#           current player.
immutable MyGameState <: AbstractGameState
	score::Int
	flags::Array{Symbol,1}
	player::Symbol
	# ...
end

# Step Three: add more to game state type
# Note:       we'll add a board and a constructor returning the initial state.
#             we'll come back to the second constructor soon.
immutable MyGameState <: AbstractGameState
	score::Int
	flags::Array{Symbol,1}
	player::Symbol
	board::Array{Symbol,2}
	MyGameState() = new(0, Symbol[], :X, fill(:N, 3, 3))
	function MyGameState(prev::MyGameState, options)
		# body
	end
end

# Step Four: overload GameIter.options
# Note:      options takes a state and an integer, returns a tuple.
#            this tuple represents a set of options representing one possible
#            next move after the current state.
#            options will be called with N=0 first, then N=1, and so on.
#            it's return values should "cycle." that is, if there are K possible
#            next moves, options(S, i) == options(S, K+i) for all i.
#            these options will be used in the second constructor started in step three.
import GameIter: options
options(state::MyGameState, N::Int) = (N%3+1, fld(N,3)%3+1)

# Step Five: complete the second constructor
# Note:      this is where the game's logic takes place. this example is for tic-tac-toe
#            FLAG_TERMINAL and FLAG_ILLEGAL are exported by GameIter.
#            these are used to flag leaf states and malformed states, respectively.
#            it would be best to define options and this constructor such that
#            malformed states are impossible, but, come on, it's just tic-tac-toe
immutable MyGameState <: AbstractGameState
	# ...
	function MyGameState(prev::MyGameState, options)
		x, y = opts
		if prev.board[x, y] === :X
			s = 0
			f = Symbol[]
			p = prev.player===:X? :O : :X
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

			if s == 1 || all(b .!= :X)
				f = [FLAG_TERMINAL]
				p = prev.player
			end

			return new(s, f, p, b)
		else
			return new(0, [FLAG_ILLEGAL], :X, fill(:X, (3,3)))
		end
	end
end

# Step Six: minimax!
# Note:     GameIter exports three minimax implementations, minimax_naive,
#           minimax_depth, and minimax_prune.
#           we'll just use the naive version for this example.
game_state = MyGameState()
println(game_state.board)
while !(FLAG_TERMINAL in game_state.board)
	state = minimax_naive(game_state)
	println(game_state.board)
end
```