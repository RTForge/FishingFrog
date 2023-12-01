extends Node3D

@export var level_time: int = 120
@onready var previous_window = DisplayServer.window_get_mode()
@onready var current_window = DisplayServer.window_get_mode()
@onready var cam = $MainCamera
@onready var level_timer = $LevelTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cam.target = $Frog.current_pad.get_camera_target()
	level_timer.start()

func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		current_window = DisplayServer.window_get_mode()
		if current_window != DisplayServer.WINDOW_MODE_FULLSCREEN:
			previous_window = current_window
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			if previous_window == DisplayServer.WINDOW_MODE_FULLSCREEN:
				previous_window = DisplayServer.WINDOW_MODE_MAXIMIZED
			DisplayServer.window_set_mode(previous_window)

#func _on_frog_score_changed(score):
#	$GameOverlay.score = score
#	print("Score: ", score)

func _on_frog_pad_changed(pad: LilyPad):
	var target: Camera3D = pad.get_camera_target()
	if target:
		cam.target = pad.get_camera_target()
	$GameOverlay.trigger_next_hint()

func _on_level_timer_timeout():
	print("Remaining time: ", level_time)
	level_time -= 1
	$GameOverlay.time_left = level_time
	if level_time < 0:
		level_timer.stop()
	
