## Supress UNUSED_SIGNAL warning - this is an event bus, signal emited and listened to from others scripts
@warning_ignore("unused_signal")
extends Node

#region Core Foundation Signals

## Fire once on game boot, after all autoloads are ready
signal game_started()

## Fire after a successful save complete
signal game_saved(slots: int)

## Fire after a successful load complete
signal game_loaded(slots: int)

#endregion

#region GameClock Signals

signal minute_passed(minute: int)
signal hour_passed(hour: int)
signal day_passed(day: int)
signal season_changed(season: int)
signal year_passed(year: int)

#endregion

#region Debug Signals

signal debug_ping(Message: String)

#endregion

#region Register Foundation

## Track which foundation are active in the current project
var active_foundation: Dictionary = {
	"core": true, # Always true - core is required! 
}

func _ready() -> void:
	print("GaneEvents: Autoload ready.")
	debug_ping.connect(_on_debug_ping)
	# call_deferred pushed this to the end of the frame AFTER the rest of the tree has had the chance to _ready first!
	call_deferred("_emit_game_started")

func register_foundation(foundation_name: String) -> void:
	active_foundation[foundation_name] = true
	print("GameEvents: registered foundation '", foundation_name, "'")

func is_foundation_active(foundation_name: String) -> bool:
	return active_foundation.get(foundation_name)

func _on_debug_ping(message: String) -> void:
	print("DEBUG PING: ", message)

func _emit_game_started() -> void:
	print("GameEvents: emitting game started.")
	game_started.emit()

#endregion
