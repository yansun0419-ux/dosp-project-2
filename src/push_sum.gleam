import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import types.{type NetworkState, type PushSumState, PushSumNetwork, PushSumNode}

/// Initialize a Push-Sum network
/// For each node i, initial state is: s = i+1, w = 1.0
/// This ensures unique starting values for the sum calculation
pub fn init_pushsum_network(
  num_nodes: Int,
  neighbor_map: List(List(Int)),
) -> NetworkState {
  let nodes =
    list.range(0, num_nodes - 1)
    |> list.zip(neighbor_map)
    |> list.fold(dict.new(), fn(acc, pair) {
      let #(node_id, neighbors) = pair
      let initial_s = int.to_float(node_id + 1)
      let node =
        PushSumNode(
          neighbors: neighbors,
          s: initial_s,
          w: 1.0,
          ratio_unchanged_count: 0,
          last_ratio: initial_s,
          active: True,
        )
      dict.insert(acc, node_id, node)
    })

  PushSumNetwork(nodes)
}

/// Simulate the Push-Sum algorithm execution
/// Recursively simulates each round until all nodes converge
/// Convergence is achieved when s/w ratio remains stable for 3 consecutive rounds
pub fn simulate_pushsum(network: NetworkState, round: Int) -> NetworkState {
  case network {
    PushSumNetwork(nodes) -> {
      // First round: Initialize node 0 to start computation
      let updated_nodes = case round {
        0 -> {
          case dict.get(nodes, 0) {
            Ok(PushSumNode(
              neighbors,
              s,
              w,
              ratio_unchanged_count,
              last_ratio,
              _active,
            )) ->
              dict.insert(
                nodes,
                0,
                PushSumNode(
                  neighbors,
                  s,
                  w,
                  ratio_unchanged_count,
                  last_ratio,
                  True,
                ),
              )
            Error(_) -> nodes
          }
        }
        _ -> nodes
      }

      // Check how many nodes are still active
      let active_count =
        dict.fold(updated_nodes, 0, fn(acc, _, node) {
          case node {
            PushSumNode(_, _, _, _, _, True) -> acc + 1
            PushSumNode(_, _, _, _, _, False) -> acc
          }
        })

      // Continue simulation if there are active nodes and within round limit
      case active_count > 0 && round < 1000 {
        True -> {
          // Simulate one round of Push-Sum computation
          let new_nodes = simulate_pushsum_round(updated_nodes)
          simulate_pushsum(PushSumNetwork(new_nodes), round + 1)
        }
        False -> PushSumNetwork(updated_nodes)
      }
    }
    _ -> network
  }
}

/// Simulate one round of the Push-Sum algorithm
/// Each active node sends half of its s,w values to a neighbor
/// Nodes track their s/w ratio and become inactive after 3 rounds of stability
fn simulate_pushsum_round(
  nodes: Dict(Int, PushSumState),
) -> Dict(Int, PushSumState) {
  dict.fold(nodes, nodes, fn(acc, node_id, node) {
    case node {
      PushSumNode(neighbors, s, w, ratio_unchanged_count, last_ratio, True) -> {
        // Send half of s,w values to first neighbor (simplified random selection)
        case neighbors {
          [neighbor, ..] -> {
            let half_s = s /. 2.0
            let half_w = w /. 2.0

            case dict.get(acc, neighbor) {
              Ok(PushSumNode(
                n_neighbors,
                n_s,
                n_w,
                n_ratio_unchanged_count,
                n_last_ratio,
                _n_active,
              )) -> {
                // Neighbor receives s,w values and updates its state
                let new_s = n_s +. half_s
                let new_w = n_w +. half_w
                let new_ratio = new_s /. new_w

                // Check if ratio change is small enough (convergence check)
                let ratio_diff = float.absolute_value(new_ratio -. n_last_ratio)
                let new_unchanged_count = case ratio_diff <. 0.0000000001 {
                  True -> n_ratio_unchanged_count + 1
                  False -> 0
                }

                // Node becomes inactive after 3 rounds of stable ratio
                let new_active = new_unchanged_count < 3

                let new_neighbor =
                  PushSumNode(
                    n_neighbors,
                    new_s,
                    new_w,
                    new_unchanged_count,
                    new_ratio,
                    new_active,
                  )
                let updated_acc = dict.insert(acc, neighbor, new_neighbor)

                // 发送者保留另一半的s,w值
                let updated_sender =
                  PushSumNode(
                    neighbors,
                    half_s,
                    half_w,
                    ratio_unchanged_count,
                    last_ratio,
                    True,
                  )
                dict.insert(updated_acc, node_id, updated_sender)
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
