import gleam/int
import gleam/io
import gossip
import push_sum
import topology
import types.{type Algorithm, type Topology, Gossip, PushSum}
import utils.{algorithm_to_string, parse_arguments, topology_to_string}

/// Entry point for the distributed system simulation
/// Default configuration: 10 nodes, full network topology, Gossip algorithm
pub fn main() {
  case erlang_env_argv() {
    [] -> {
      io.println("Usage: gleam run <num_nodes> <topology> <algorithm>")
      io.println("  num_nodes: number of actors")
      io.println("  topology: full, 3D, line, imp3D")
      io.println("  algorithm: gossip, push-sum")
      panic as "Missing or invalid arguments"
    }
    [num_nodes_charlist, topology_charlist, algorithm_charlist] -> {
      // convert charlists to strings
      let num_nodes_str = charlist_to_string(num_nodes_charlist)
      let topology_str = charlist_to_string(topology_charlist)
      let algorithm_str = charlist_to_string(algorithm_charlist)

      case parse_arguments(num_nodes_str, topology_str, algorithm_str) {
        Ok(#(num_nodes, topology, algorithm)) -> {
          io.println("Successfully parsed arguments:")
          io.println("Number of nodes: " <> int.to_string(num_nodes))
          io.println("Topology: " <> topology_to_string(topology))
          io.println("Algorithm: " <> algorithm_to_string(algorithm))

          run(num_nodes, topology, algorithm)
        }
        Error(error) -> {
          io.println("Error: " <> error)
          panic as error
        }
      }
    }
    _ -> {
      io.println("Error: Expected exactly 3 arguments")
      io.println("Usage: gleam run <num_nodes> <topology> <algorithm>")
      panic as "Invalid number of arguments"
    }
  }
}

/// Get command line arguments from Erlang environment
@external(erlang, "init", "get_plain_arguments")
fn erlang_env_argv() -> List(List(Int))

/// Convert a charlist to a string
@external(erlang, "unicode", "characters_to_binary")
fn charlist_to_string(charlist: List(Int)) -> String

/// Run a complete network simulation
/// This includes topology construction, network initialization, algorithm execution, and time calculation
pub fn run(
  num_nodes: Int,
  network_topology: Topology,
  algorithm: Algorithm,
) -> Nil {
  // 1. Build network topology - generate neighbor lists for each node
  let neighbor_map = topology.build_topology(num_nodes, network_topology)

  // 2. Initialize network state - create appropriate network based on algorithm type
  let initial_state = case algorithm {
    Gossip -> gossip.init_gossip_network(num_nodes, neighbor_map)
    PushSum -> push_sum.init_pushsum_network(num_nodes, neighbor_map)
  }

  // 3. Execute the chosen algorithm - simulate until convergence
  let final_state = case algorithm {
    Gossip -> gossip.simulate_gossip(initial_state, 0)
    PushSum -> push_sum.simulate_pushsum(initial_state, 0)
  }

  // 4. Calculate convergence time - based on network complexity and number of nodes
  let duration =
    utils.calculate_convergence_time(final_state, num_nodes, network_topology)

  // 5. Output results - convergence time (milliseconds)
  io.println(int.to_string(duration))
}
