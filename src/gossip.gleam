import gleam/erlang/process.{type Pid}
import gleam/int
import gleam/otp/actor.{type Actor}
import gleam/list
import types.{
  // Use the new unified Action type
  type Action,
  type ActorState,
  type GossipState,
  ContinueWork,
  GossipActor,
  GossipState,
  SendRumor,
}

pub fn initial_state() -> ActorState {
  GossipActor(GossipState(rumor_count: 0, neighbors: []))
}

pub fn set_neighbors(
  state: GossipState,
  neighbors: List(Actor(types.ActorMessage)),
) -> GossipState {
  GossipState(..state, neighbors: neighbors)
}

pub fn handle_start(
  state: GossipState,
  me: Actor(types.ActorMessage),
) -> #(ActorState, List(Action), Bool) {
  let new_state = GossipState(..state, rumor_count: 1)
  let actions = [ContinueWork(me)]
  #(GossipActor(new_state), actions, False)
}

pub fn handle_rumor(
  state: GossipState,
) -> #(ActorState, List(Action), Bool) {
  case state.rumor_count >= 10 {
    True -> #(GossipActor(state), [], False)
    False -> {
      let new_count = state.rumor_count + 1
      let new_state = GossipState(..state, rumor_count: new_count)
      case new_count == 10 {
        True -> #(GossipActor(new_state), [], True)
        False -> #(GossipActor(new_state), [], False)
      }
    }
  }
}

pub fn handle_work(
  state: GossipState,
  me: Actor(types.ActorMessage),
) -> #(ActorState, List(Action), Bool) {
  case state.rumor_count == 0 || state.rumor_count >= 10 {
    True -> #(GossipActor(state), [], False)
    False -> {
      let actions = case list.is_empty(state.neighbors) {
        True -> []
        False -> {
          let random_index = int.random(list.length(state.neighbors))
          case list.drop(state.neighbors, random_index) |> list.first {
            Ok(neighbor) -> [SendRumor(neighbor)]
            Error(_) -> []
          }
        }
      }
      let actions = list.append(actions, [ContinueWork(me)])
      #(GossipActor(state), actions, False)
    }
  }
}