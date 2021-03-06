import JSON
import MCTS: AbstractTreeVisualizer, node_tag, tooltip_tag, create_json, blink

mutable struct DESPOTVisualizer <: AbstractTreeVisualizer
    root::VNode
end

DESPOTVisualizer(solver::DESPOTSolver) = DESPOTVisualizer(solver.root)

blink(solver::DESPOTSolver) = blink(DESPOTVisualizer(solver))

const NodeDict = Dict{Int, Dict{String, Any}}

function create_json(v::DESPOTVisualizer)
    node_dict = NodeDict()
    dict = recursive_push!(node_dict, v.root, "root (Q values at action nodes are upper bounds)")
    json = JSON.json(node_dict)
    return (json, 1)
end

function recursive_push!(nd::NodeDict, n::VNode, obs, parent_id=-1)
    id = length(nd) + 1
    if parent_id > 0
        push!(nd[parent_id]["children_ids"], id)
    end
    @assert n.n_visits==0
    nd[id] = Dict("id"=>id,
                  "type"=>:V,
                  "children_ids"=>Array{Int}(0),
                  "tag"=>node_tag(obs),
                  "tt_tag"=>tooltip_tag(obs),
                  "N"=>length(n.particles)
                  )
    for (a,c) in n.q_nodes
        recursive_push!(nd, c, id)
    end
    return nd
end

function recursive_push!{S,A,O,B}(nd::NodeDict, n::QNode{S,A,O,B}, parent_id=-1)
    id = length(nd) + 1
    if parent_id > 0
        push!(nd[parent_id]["children_ids"], id)
    end
    nd[id] = Dict("id"=>id,
                  "type"=>:action,
                  "children_ids"=>Array{Int}(0),
                  "tag"=>node_tag(n.action),
                  "tt_tag"=>tooltip_tag(n.action),
                  "N"=>sum(length(last(pair).particles) for pair in n.obs_and_nodes),
                  # "Q"=>"between $(get_lower_bound(n)) and $(get_upper_bound(n))"
                  "Q"=>get_upper_bound(n)
                  )
    for (o,c) in n.obs_and_nodes
        recursive_push!(nd, c, o, id)
    end
    return nd
end
