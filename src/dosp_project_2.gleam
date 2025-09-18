import gleam/int
import gleam/io
import gossip
import push_sum
import topology
import types.{type Algorithm, type Topology, Full, Gossip, PushSum}
import utils

/// Entry point for the distributed system simulation
/// Default configuration: 10 nodes, full network topology, Gossip algorithm
pub fn main() -> Nil {
  run_simulation(10, Full, Gossip)
}

/// Run a complete network simulation
/// This includes topology construction, network initialization, algorithm execution, and time calculation
pub fn run_simulation(
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
