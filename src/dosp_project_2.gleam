import gleam/int
import gleam/io
import gossip
import push_sum
import topology
import types.{type Algorithm, type Topology, Gossip, PushSum}
import utils.{algorithm_to_string, parse_arguments, topology_to_string}

// Erlang FFI for timing
@external(erlang, "erlang", "monotonic_time")
fn os_timestamp() -> Int

/// Entry point for the distributed system simulation
pub fn main() {
  case erlang_env_argv() {
    [] -> {
      io.println("Usage: gleam run -- <num_nodes> <topology> <algorithm>")
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
      io.println("Usage: gleam run -- <num_nodes> <topology> <algorithm>")
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
pub fn run(
  num_nodes: Int,
  network_topology: Topology,
  algorithm: Algorithm,
) -> Nil {
  // 1. Build network topology
  let neighbor_map = topology.build_topology(num_nodes, network_topology)

  // 2. Initialize network state
  let initial_state = case algorithm {
    Gossip -> gossip.init_gossip_network(num_nodes, neighbor_map)
    PushSum -> push_sum.init_pushsum_network(num_nodes, neighbor_map)
  }

  // Start timer
  let start_time = os_timestamp()

  // 3. Execute the chosen algorithm
  let _final_state = case algorithm {
    Gossip -> gossip.simulate_gossip(initial_state, 0)
    PushSum -> push_sum.simulate_pushsum(initial_state, 0)
  }

  // Stop timer and calculate duration
  let end_time = os_timestamp()
  // timer_now_diff returns microseconds, so we divide by 1000 for milliseconds
  let duration_ms = {end_time - start_time} / 1000

  // 4. Output results
  io.println("Convergence time: " <> int.to_string(duration_ms) <> " ms")
}