module GameIter

import Base: start, done, next
export AbstractGameState
export FLAG_ILLEGAL, FLAG_TERMINAL
export start, done, next
export minimax, minimax_depth, minimax_prune, minimax_prune_depth

abstract AbstractGameState

const FLAG_ILLEGAL  = :FLAG_ILLEGAL
const FLAG_TERMINAL = :FLAG_TERMINAL

options()                                       = ()
start{T<:AbstractGameState}(S::T)               = (0, false)
done{T<:AbstractGameState}(S::T, N::(Int,Bool)) = N[2] && options(S,0)==options(S,N[1])
next{T<:AbstractGameState}(S::T, N::(Int,Bool)) = (T(S,options(S,N[1])), (N[1]+1, true))


# Note: I don't think we need to implement expectiminimax.
#       Wouldn't it be better to say the dice is a terrible opponent?
#       That is, we still assume it's going to make the best move as
#       a just-in-case. That is further, we minimize the maximum damage
#       the dice can do.
minimax{T<:AbstractGameState}(S::T)                    = minimax_depth(S, typemax(Uint))
minimax_depth{T<:AbstractGameState}(S::T, depth)       = __minimax_depth(S, uint(depth))[1]
minimax_prune{T<:AbstractGameState}(S::T)              = minimax_prune_depth(S, typemax(Uint))
minimax_prune_depth{T<:AbstractGameState}(S::T, depth) = __minimax_prune(S, uint(depth),
                                                             Dict{Symbol,typeof(S.score)}())[1]

function __minimax_depth{T<:AbstractGameState}(S::T, depth::Uint)
	if FLAG_ILLEGAL in S.flags
		return (nothing, nothing)
	elseif depth == 0 || FLAG_TERMINAL in S.flags
		return (S, S.score)
	else
		max_score = typemin(typeof(S.score))+1
		best_child = nothing
		for child in S
			leaf, score = __minimax_depth(child, depth-1)
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

# Note: In original alpha-beta pruning,
#       alpha = max_score of maximizing player, and
#       beta  = min_score of minimizing player.
#       But ij GameIter, all players other than current are assumed to be
#       minimizing and turns are not necessarily passed back and forth.
#       So, here we can say,
#       alpha = max_score of current player,
#       beta  = max_scores of other players, and
#       -beta = min_scores of other players.
#       scores is a dict of player => that player's max_score
function __minimax_prune{T<:AbstractGameState}(S::T, depth::Uint, scores::Dict)
	if FLAG_ILLEGAL in S.flags
		return (nothing, nothing)
	elseif depth == 0 || FLAG_TERMINAL in S.flags
		return (S, S.score)
	else
		scores[S.player] = typemin(typeof(S.score))+1
		copy_scores = copy(scores)
		best_child = nothing
		for child in S
			leaf, score = __minimax_prune(child, depth-1, copy_scores)
			if leaf !== nothing
				if child.player != S.player
					score = -score
				end

				if score > scores[S.player]
					scores[S.player] = score
					best_child = child
					cutoff = true
					for score in values(scores)
						if scores[S.player] < -score
							cutoff = false
							break
						end
					end

					if cutoff
						break
					end
				end
			end
		end

		return (best_child, scores[S.player])
	end
end

end