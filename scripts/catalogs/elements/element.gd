@abstract class_name Element extends RefCounted

enum Type {
	EMPTY,
	SOLID,
	LIQUID,
	GAS, 
	PLASMA, 
	PARTICLE
}

var id: int

var vel: Vector3

var frictionFactor: float
var stoppedMovingThreshold: int = 1
