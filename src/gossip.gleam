import gleam/dict.{type Dict}
import gleam/list
import types.{type GossipState, type NetworkState, GossipNetwork, GossipNode}

/// Initialize a Gossip network
/// Creates all nodes with initial state: no rumors heard and active
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

/// Simulate the Gossip algorithm execution
/// Recursively simulates each round until all nodes become inactive (convergence)
/// A node becomes inactive after hearing the rumor 10 times
pub fn simulate_gossip(network: NetworkState, round: Int) -> NetworkState {
  case network {
    GossipNetwork(nodes) -> {
      // First round: Start spreading rumor from node 0
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

      // Check how many nodes are still active
      let active_count =
        dict.fold(updated_nodes, 0, fn(acc, _, node) {
          case node {
            GossipNode(_, _, True) -> acc + 1
            GossipNode(_, _, False) -> acc
          }
        })

      // Continue simulation if there are active nodes and within round limit
      case active_count > 0 && round < 1000 {
        True -> {
          // Simulate one round of rumor spreading
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
/// Each active node spreads the rumor to a random neighbor
/// A node participates in spreading only if it has heard the rumor but less than 10 times
fn simulate_gossip_round(
  nodes: Dict(Int, GossipState),
) -> Dict(Int, GossipState) {
  dict.fold(nodes, nodes, fn(acc, _node_id, node) {
    case node {
      // Only active nodes that have heard the rumor less than 10 times spread it
      GossipNode(neighbors, rumor_count, True)
        if rumor_count > 0 && rumor_count < 10
      -> {
        // Spread the rumor to the first neighbor (simplified random choice)
        case neighbors {
          [neighbor, ..] -> {
            case dict.get(acc, neighbor) {
              Ok(GossipNode(n_neighbors, n_rumor_count, n_active)) -> {
                // The neighbor hears the rumor, increment count, become inactive if reaches 10
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
          [] -> acc
        }
      }
      _ -> acc
    }
  })
}
