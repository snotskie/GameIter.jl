module GameIter

import Base: start, done, next
export AbstractGameState
export FLAG_ILLEGAL, FLAG_TERMINAL
export start, done, next
export minimax_depth, minimax_prune, minimax_naive

abstract AbstractGameState

const FLAG_ILLEGAL  = :FLAG_ILLEGAL
const FLAG_TERMINAL = :FLAG_TERMINAL

options()                                       = ()
start{T<:AbstractGameState}(S::T)               = (0, false)
done{T<:AbstractGameState}(S::T, N::(Int,Bool)) = N[2] && options(S,0)==options(S,N[1])
next{T<:AbstractGameState}(S::T, N::(Int,Bool)) = (T(S,options(S,N[1])), (N[1]+1, true))

minimax_depth{T<:AbstractGameState}(S::T, depth) = __minimax_depth(S, uint(depth))[1]
minimax_naive{T<:AbstractGameState}(S::T)        = __minimax_depth(S, typemax(Uint))[1]
minimax_prune{T<:AbstractGameState}(S::T)        = __minimax_prune(S, typemin(typeof(S.score))+1,
                                                       typemax(typeof(S.score))-1)[1]

function __minimax_depth{T<:AbstractGameState}(S::T, depth::Uint)
	if FLAG_ILLEGAL in S.flags
		return (nothing, nothing)
	elseif depth == 0 || FLAG_TERMINAL in S.flags
		return (S, S.score)
	else
		max_score = typemin(typeof(S.score))
		best_child = nothing
		for child in S
			(leaf, score) = __minimax_depth(child, depth-1)
			if leaf !== nothing
				if child.player != S.player
					score = -score
				end

				if score > max_score
					max_score = score
					best_child = child
				end
			end
		end

		return (best_child, max_score)
	end
end

function __minimax_prune{T<:AbstractGameState}(S::T, alpha, beta)
	if FLAG_ILLEGAL in S.flags
		return (nothing, nothing)
	elseif FLAG_TERMINAL in S.flags
		return (S, S.score)
	else
		best_child = nothing
		for child in S
			(leaf, score) = __minimax_prune(child, -beta, -alpha)

			if leaf !== nothing
				if child.player != S.player
					score = -score
				end

				if -score > alpha
					alpha = -score
					best_child = child
					if beta <= alpha
						break
					end
				end
			end
		end

		return (best_child, alpha)
	end
end

end