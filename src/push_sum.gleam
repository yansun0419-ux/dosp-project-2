import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/list
import types.{
  // Use the new unified Action type
  type Action,
  type ActorMessage,
  type ActorState,
  type PushSumState,
  ContinueWork,
  PushSumActor,
  PushSumState,
  SendPushSum,
}

pub fn initial_state(id: Int) -> ActorState {
  let s = int.to_float(id + 1)
  PushSumActor(PushSumState(
    s: s,
    w: 1.0,
    last_ratio: s,
    ratio_unchanged_count: 0,
    neighbors: [],
  ))
}

pub fn set_neighbors(state: PushSumState, neighbors: List(Subject(ActorMessage))) -> PushSumState {
  PushSumState(..state, neighbors: neighbors)
}

pub fn handle_start(
  state: PushSumState,
  me: Subject(ActorMessage),
) -> #(ActorState, List(Action), Bool) {
  #(PushSumActor(state), [ContinueWork(me)], False)
}

pub fn handle_push_sum(
  state: PushSumState,
  received_s: Float,
  received_w: Float,
) -> #(ActorState, List(Action), Bool) {
  let new_s = state.s +. received_s
  let new_w = state.w +. received_w
  let new_ratio = case new_w {
    0.0 -> 0.0
    _ -> new_s /. new_w
  }
  let ratio_diff = float.absolute_value(new_ratio -. state.last_ratio)
  let new_unchanged_count = case ratio_diff <. 0.0000000001 {
    True -> state.ratio_unchanged_count + 1
    False -> 0
  }
  let new_state = PushSumState(
    ..state,
    s: new_s,
    w: new_w,
    last_ratio: new_ratio,
    ratio_unchanged_count: new_unchanged_count,
  )
  case new_unchanged_count >= 3 {
    True -> #(PushSumActor(new_state), [], True)
    False -> #(PushSumActor(new_state), [], False)
  }
}

pub fn handle_work(
  state: PushSumState,
  me: Subject(ActorMessage),
) -> #(ActorState, List(Action), Bool) {
  case state.ratio_unchanged_count >= 3 {
    True -> #(PushSumActor(state), [], True)
    False -> {
      let #(send_actions, new_state) =
        case list.is_empty(state.neighbors) {
          True -> #([], state)
          False -> {
            let random_index = int.random(list.length(state.neighbors))
            case list.drop(state.neighbors, random_index) |> list.first {
              Ok(neighbor) -> {
                let half_s = state.s /. 2.0
                let half_w = state.w /. 2.0
                let updated_sender_state =
                  PushSumState(..state, s: half_s, w: half_w)
                let actions = [SendPushSum(neighbor, half_s, half_w)]
                #(actions, updated_sender_state)
              }
              Error(_) -> #([], state)
            }
          }
        }
      let all_actions = list.append(send_actions, [ContinueWork(me)])
      #(PushSumActor(new_state), all_actions, False)
    }
  }
}