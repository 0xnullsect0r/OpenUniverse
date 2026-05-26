class_name Timeline
extends RefCounted

# Ring buffer of simulation snapshots for the scrubber / rewind.
# Each snapshot: { "time": float, "bodies": Array[Dictionary] }

var _snapshots: Array = []
var _capacity:  int   = PhysicsConstants.MAX_SNAPSHOTS
var _head:      int   = 0   # index of oldest snapshot
var _count:     int   = 0

var oldest_time: float = 0.0
var newest_time: float = 0.0

func push_snapshot() -> void:
	var snap := {
		"time":   GameState.simulation_time,
		"bodies": UniverseManager.take_snapshot(),
	}
	var idx: int
	if _count < _capacity:
		idx = _count
		_count += 1
	else:
		idx = _head
		_head = (_head + 1) % _capacity
	_snapshots.resize(max(_snapshots.size(), idx + 1))
	_snapshots[idx] = snap
	oldest_time = _snapshots[_head]["time"]
	newest_time = snap["time"]

func seek(target_time: float) -> void:
	if _count == 0:
		return
	# Find the snapshot closest to target_time
	var best_idx  := 0
	var best_diff := INF
	for i in range(_count):
		var real_i := (_head + i) % _capacity
		if real_i >= _snapshots.size():
			continue
		var diff := absf(_snapshots[real_i]["time"] - target_time)
		if diff < best_diff:
			best_diff = diff
			best_idx  = real_i
	var snap := _snapshots[best_idx]
	GameState.simulation_time = snap["time"]
	UniverseManager.restore_snapshot(snap["bodies"])
	EventBus.timeline_scrubbed.emit(snap["time"])

func clear() -> void:
	_snapshots.clear()
	_head  = 0
	_count = 0
	oldest_time = 0.0
	newest_time = 0.0

func get_fraction() -> float:
	if newest_time <= oldest_time:
		return 1.0
	return (GameState.simulation_time - oldest_time) / (newest_time - oldest_time)
