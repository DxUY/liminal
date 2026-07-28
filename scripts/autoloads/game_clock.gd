extends Node

# season enum
enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

# Calendar Constants
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 28

# Time scale

## Real seconds that passed per in-game-minutes
## Lower = faster clock
var second_per_minutes: float = 1.0 # 0.1 is MAX! Breaks NPC Pathing

# CLock State
var minute: int = 0
var hour: int = 6
var day: int = 1
var current_season: int = Season.SPRING
var year: int = 1

var _timer = Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = second_per_minutes
	_timer.autostart = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	print("GameClock: Ready -", get_datetime_string())

func _on_timer_timeout() -> void:
	_timer.wait_time = maxf(second_per_minutes, 0.1)
	_advance_minutes()

# Cascade of the Game Clock

func _advance_minutes() -> void:
	minute += 1
	GameEvents.minute_passed.emit(minute)
	if minute >= MINUTES_PER_HOUR:
		minute = 0
		_advance_hour()

func _advance_hour() -> void:
	hour += 1
	GameEvents.hour_passed.emit(hour)
	if hour >= HOURS_PER_DAY:
		minute = 0
		_advance_day()

func _advance_day() -> void:
	day += 1
	GameEvents.day_passed.emit(day)
	if day >= DAYS_PER_SEASON:
		day = 1
		_advance_season()

func _advance_season() -> void:
	current_season = (current_season + 1) % 4 as Season
	GameEvents.season_changed.emit(current_season)
	if current_season == Season.SPRING:
		_advance_year()

func _advance_year() -> void:
	year += 1
	GameEvents.year_passed.emit(year)

#region Public API

## Returns the season name as a captialized string
func get_season_name() -> String:
	return Season.keys()[current_season].capitalize()

## Return a readble datetime string
## i.e "Spring - Day 1, Year 1 06:00"
func get_datetime_string() -> String:
	return "%s: Day %d, Year %d %02d:%02d" % \
	[get_season_name(), day, year, hour, minute]

#endregion

#region Savable Contract

func get_save_id() -> String:
	return "clock"

func save_data() -> Dictionary:
	return {
		"minute": minute,
		"hour": hour,
		"day": day,
		"current_season": current_season,
		"year": year,
	}

func load_data(data: Dictionary) -> void:
	minute = data.get("minute", 0)
	hour = data.get("hour", 6)
	day = data.get("day", 1)
	current_season = data.get("current_season", Season.SPRING)
	year = data.get("year", 1)
	print("GameClock: Loaded - ", get_datetime_string())

#endregion
