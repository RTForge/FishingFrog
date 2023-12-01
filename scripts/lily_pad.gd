class_name LilyPad extends Node3D

@export var left_pad: LilyPad
@export var right_pad: LilyPad
@export var forward_pad: LilyPad
@export var backward_pad: LilyPad

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_camera_target() -> Camera3D:
	for child in get_children():
		if child is Camera3D:
			return child
	return null
