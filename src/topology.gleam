import gleam/float
import gleam/int
import gleam/list
import types.{type Topology, Full, ImperfectThreeD, Line, ThreeD}

/// Build a network topology based on the type and number of nodes
/// Returns a list of neighbor lists, where each sublist contains the neighbors of a node
pub fn build_topology(num_nodes: Int, topology: Topology) -> List(List(Int)) {
  case topology {
    Full -> build_full_topology(num_nodes)
    ThreeD -> build_3d_topology(num_nodes)
    Line -> build_line_topology(num_nodes)
    ImperfectThreeD -> build_imperfect_3d_topology(num_nodes)
  }
}

/// Build a fully connected topology
/// Each node is connected to all other nodes except itself
/// This provides the fastest convergence but highest network complexity
fn build_full_topology(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    list.range(0, num_nodes - 1)
    |> list.filter(fn(j) { j != i })
  })
}

/// Build a line topology
/// Nodes are arranged in a line, each node has at most 2 neighbors (left and right)
/// This is the simplest topology but has the slowest convergence
fn build_line_topology(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    case i {
      // First node: only has right neighbor
      0 -> [1]
      // Last node: only has left neighbor
      j if j == num_nodes - 1 -> [num_nodes - 2]
      // Middle nodes: have both left and right neighbors
      _ -> [i - 1, i + 1]
    }
  })
}

/// Build a 3D grid topology
/// Nodes are arranged in a 3D cube, each node has up to 6 neighbors
/// (top, bottom, left, right, front, back)
/// Provides a good balance between network complexity and convergence speed
fn build_3d_topology(num_nodes: Int) -> List(List(Int)) {
  let side_length = calculate_cube_side(num_nodes)
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) { get_3d_neighbors(i, side_length, num_nodes) })
}

/// Build an imperfect 3D grid topology
/// Based on 3D grid, but each node has an additional random neighbor
/// This improves convergence speed by creating potential shortcuts in the network
fn build_imperfect_3d_topology(num_nodes: Int) -> List(List(Int)) {
  let side_length = calculate_cube_side(num_nodes)
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    let grid_neighbors = get_3d_neighbors(i, side_length, num_nodes)
    let random_neighbor = int.random(num_nodes)
    case
      list.contains(grid_neighbors, random_neighbor) || random_neighbor == i
    {
      // Skip if random neighbor is already a grid neighbor or self
      True -> grid_neighbors
      // Add the random neighbor to the list
      False -> [random_neighbor, ..grid_neighbors]
    }
  })
}

/// Calculate the side length of the 3D cube
/// Given the number of nodes, computes the minimum cube size that can contain all nodes
fn calculate_cube_side(num_nodes: Int) -> Int {
  let side_float = float.power(int.to_float(num_nodes), 1.0 /. 3.0)
  case side_float {
    Ok(side) -> float.ceiling(side) |> float.round
    Error(_) -> 1
  }
}

/// Get all neighbors of a node in the 3D grid
/// Converts 1D index to 3D coordinates and finds neighbors in all 6 directions
/// Handles edge cases and ensures all neighbor indices are valid
fn get_3d_neighbors(index: Int, side_length: Int, total_nodes: Int) -> List(Int) {
  // Convert 1D index to 3D coordinates (x, y, z)
  let x = index % side_length
  let y = { index / side_length } % side_length
  let z = index / { side_length * side_length }

  // Potential neighbor coordinates in all 6 directions
  let potential_neighbors = [
    #(x - 1, y, z),
    #(x + 1, y, z),
    // Left-Right
    #(x, y - 1, z),
    #(x, y + 1, z),
    // Front-Back
    #(x, y, z - 1),
    #(x, y, z + 1),
    // Up-Down
  ]

  potential_neighbors
  |> list.filter(fn(coord) {
    let #(nx, ny, nz) = coord
    // Check if coordinates are within cube boundaries
    nx >= 0
    && nx < side_length
    && ny >= 0
    && ny < side_length
    && nz >= 0
    && nz < side_length
  })
  |> list.map(fn(coord) {
    let #(nx, ny, nz) = coord
    // Convert 3D coordinates back to 1D index
    nx + ny * side_length + nz * side_length * side_length
  })
  |> list.filter(fn(neighbor_index) {
    // Ensure neighbor index is within valid range
    neighbor_index < total_nodes
  })
}
