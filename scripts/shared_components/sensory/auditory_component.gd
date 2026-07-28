class_name AuditoryComponent extends Node

@export_range(1.0, 100.0, 0.5, "suffix:m") var hearing_range: float = 10.0
@export_range(0.0, 1.0, 0.01) var hearing_threshold: float = 0.1
@export var hearing_enabled: bool = true

@onready var blackboard_component: BlackboardComponent = %BlackboardComponent
