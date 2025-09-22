import gleam/erlang/process.{type Pid}
import gleam/otp/actor.{type Actor}

// --- Algorithm & Topology Enums (Unchanged) ---
pub type Algorithm {
  Gossip
  PushSum
}

pub type Topology {
  Full
  ThreeD
  Line
  ImperfectThreeD
}

// --- Actor & Node Messages (Unchanged) ---
pub type NodeMessage {
  Rumor
  PushSumValues(s: Float, w: Float)
}

pub type ActorMessage {
  Init(neighbors: List(Actor(ActorMessage)))
  Start
  Node(from: Pid, msg: NodeMessage)
  Work
}

// --- Supervisor Messages ---
pub type SupervisorMessage {
  Converged
}

// --- State Definitions (Unchanged) ---
pub type GossipState {
  GossipState(rumor_count: Int, neighbors: List(Actor(ActorMessage)))
}

pub type PushSumState {
  PushSumState(
    s: Float,
    w: Float,
    last_ratio: Float,
    ratio_unchanged_count: Int,
    neighbors: List(Actor(ActorMessage)),
  )
}

pub type ActorState {
  GossipActor(GossipState)
  PushSumActor(PushSumState)
}

// --- NEW: Unified Action Type ---
// This defines all possible actions an actor can take, regardless of algorithm.
pub type Action {
  SendRumor(to: Actor(ActorMessage))
  SendPushSum(to: Actor(ActorMessage), s: Float, w: Float)
  ContinueWork(me: Actor(ActorMessage))
}