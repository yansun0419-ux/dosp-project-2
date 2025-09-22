import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import types.{type GossipState, type NetworkState, GossipNetwork, GossipNode}

pub fn init_gossip_network(
  num_nodes: Int,
  neighbor_map: List(List(Int)),
) -> NetworkState {
  let nodes =
    list.range(0, num_nodes - 1)
    |> list.zip(neighbor_map)
    |> list.fold(dict.new(), fn(acc, pair) {
      let #(node_id, neighbors) = pair
      let node = GossipNode(neighbors: neighbors, rumor_count: 0, active: True)
      dict.insert(acc, node_id, node)
    })

  GossipNetwork(nodes)
}

pub fn simulate_gossip(network: NetworkState, round: Int) -> NetworkState {
  case network {
    GossipNetwork(nodes) -> {
      let updated_nodes = case round {
        0 -> {
          case dict.get(nodes, 0) {
            Ok(GossipNode(neighbors, _, active)) ->
              dict.insert(nodes, 0, GossipNode(neighbors, 1, active))
            Error(_) -> nodes
          }
        }
        _ -> nodes
      }

      let active_count =
        dict.fold(updated_nodes, 0, fn(acc, _, node) {
          case node {
            GossipNode(_, _, True) -> acc + 1
            GossipNode(_, _, False) -> acc
          }
        })

      case active_count > 0 && round < 1000 {
        True -> {
          let new_nodes = simulate_gossip_round(updated_nodes)
          simulate_gossip(GossipNetwork(new_nodes), round + 1)
        }
        False -> GossipNetwork(updated_nodes)
      }
    }
    _ -> network
  }
}

/// Simulate one round of the Gossip algorithm
fn simulate_gossip_round(
  nodes: Dict(Int, GossipState),
) -> Dict(Int, GossipState) {
  dict.fold(nodes, nodes, fn(acc, _node_id, node) {
    case node {
      // MODIFIED: Pattern `[_, ..] as neighbors` checks for a non-empty list
      // without calling a function in the guard.
      GossipNode([_, ..] as neighbors, rumor_count, True)
        if rumor_count > 0 && rumor_count < 10 -> {
        // Select a random neighbor
        let random_index = int.random(list.length(neighbors))
        case list.drop(neighbors, random_index) |> list.first() {
          Ok(neighbor) -> {
            case dict.get(acc, neighbor) {
              Ok(GossipNode(n_neighbors, n_rumor_count, n_active)) -> {
                let new_neighbor =
                  GossipNode(
                    n_neighbors,
                    n_rumor_count + 1,
                    n_active && n_rumor_count + 1 < 10,
                  )
                dict.insert(acc, neighbor, new_neighbor)
              }
              Error(_) -> acc
            }
          }
          Error(_) -> acc
        }
      }
      _ -> acc
    }
  })
}