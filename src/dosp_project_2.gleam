// src/dosp_project_2.gleam

import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gossip
import push_sum
import topology
import types.{type Algorithm, type Topology, Gossip, PushSum}
import utils

// Erlang FFI for timing
@external(erlang, "erlang", "monotonic_time")
fn os_timestamp() -> Int

// Main supervisor logic
fn await_convergence(count: Int, num_nodes: Int) {
  case count >= num_nodes {
    True -> Nil // All nodes have converged
    False -> {
      use <- process.receive()
      await_convergence(count + 1, num_nodes)
    }
  }
}

pub fn main() {
  case utils.erlang_env_argv() {
    [num_nodes_str, topology_str, algorithm_str] -> {
      case utils.parse_arguments(num_nodes_str, topology_str, algorithm_str) {
        Ok(#(num_nodes, t, a)) -> run(num_nodes, t, a)
        Error(e) -> io.println("Error: " <> e)
      }
    }
    _ -> io.println("Usage: gleam run -- <nodes> <topo> <algo>")
  }
}

pub fn run(
  num_nodes: Int,
  network_topology: Topology,
  algorithm: Algorithm,
) -> Nil {
  io.println("Building topology...")
  let neighbor_indices = topology.build_topology(num_nodes, network_topology)

  let supervisor = process.self()

  io.println("Spawning actors...")
  // Spawn all the actors first and get their Pids.
  let actors =
    list.range(0, num_nodes - 1)
    |> list.map(fn(i) {
      let initial_actor_state = case algorithm {
        Gossip -> gossip.initial_state()
        PushSum -> push_sum.initial_state(i)
      }
      // The actor's state is a tuple of its specific state and the supervisor's Pid
      let full_initial_state = #(initial_actor_state, supervisor)
      // The start function expects a function that returns the message handler
      actor.start(full_initial_state, fn(_) { actor.loop })
    })

  io.println("Initializing neighbors...")
  // Now, tell each actor who its neighbors are.
  actors
  |> list.zip(neighbor_indices)
  |> list.each(fn(pair) { // pair is #(Ok(actor.Actor), List(Int))
    let #(Ok(node_actor), neighbors) = pair
    let neighbor_handles =
      list.map(neighbors, fn(i) { list.at(actors, i) })
      |> list.filter_map(fn(res) { result.then(res, Ok) })
    actor.send(node_actor, types.Init(neighbor_handles))
  })

  // Start the timer right before kicking off the simulation
  let start_time = os_timestamp()
  io.println("Starting simulation...")

  // Start the simulation by sending a message to the first actor.
  case actors {
    [Ok(first), ..] -> actor.send(first, types.Start)
    [] -> Nil
  }

  // Wait until all actors have sent a "Converged" message.
  await_convergence(0, num_nodes)

  let end_time = os_timestamp()
  let duration_ns = end_time - start_time
  let duration_ms = duration_ns / 1_000_000

  io.println("Convergence time: " <> int.to_string(duration_ms) <> " ms")

  // Cleanly stop all actors
  actors
  |> list.filter_map(fn(res) { result.then(res, Ok) })
  |> list.each(actor.stop)
}