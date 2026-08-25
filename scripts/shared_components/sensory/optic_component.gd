class_name OpticComponent extends Node

@export_range(1.0, 100.0, 0.5, "suffix:m")
var vision_range: float = 20.0

@export_range(1.0, 360.0, 1.0, "suffix:°")
var field_of_view: float = 120.0

@export var visible_light: bool = true
@export var night_vision: bool = false
@export var thermal_vision: bool = false
@export var xray_vision: bool = false

@export var vision_enabled: bool = true

@onready var blackboard_component: BlackboardComponent = %BlackboardComponent
