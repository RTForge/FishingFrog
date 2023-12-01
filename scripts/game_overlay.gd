extends Control

@export var time_left: int: set = _set_time_left
@export var paused: bool: set = _set_paused

var score = 0
var pending_points = 0

@onready var needs_motion_hint = ProjectSettings.get_setting("HintsEnabled", false)
@onready var needs_fishing_hint = ProjectSettings.get_setting("HintsEnabled", false)
@onready var needs_habitat_hint = ProjectSettings.get_setting("HintsEnabled", false)
@onready var needs_depletion_hint = ProjectSettings.get_setting("HintsEnabled", false)

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(1.0).timeout
	var tween = create_tween()
	tween.tween_property(%Fader, "color", Color.TRANSPARENT, 0.5)
	await tween.finished
	trigger_next_hint()
	%Fader.visible = false

func _input(event):
	if Input.is_action_just_pressed("toggle_pause"):
		_toggle_pause()
		
func _toggle_pause():
		paused = !paused
		
		if paused:
			Engine.time_scale = 0
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Engine.time_scale = 1
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		get_tree().paused = paused

func _set_time_left(value):
	time_left = value
	%TimeValue.text = str(value)
	if time_left <= 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		$GameOverPanel.visible = true
	
func _set_paused(value):
	paused = value
	%PausePanel.visible = value

func _on_points_added(value):
	pending_points += value
	$ScoreTimer.start()
	trigger_next_hint()

func _on_quit_button_pressed():
	Engine.time_scale = 1
	get_tree().paused = false
	%Fader.visible = true
	var tween = create_tween()
	tween.tween_property(%Fader, "color", Color.BLACK, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_replay_button_pressed():
	ProjectSettings.set_setting("HintsEnabled", false)
	get_tree().paused = false
	%Fader.visible = true
	var tween = create_tween()
	tween.tween_property(%Fader, "color", Color.BLACK, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/level1.tscn")

func _on_score_timer_timeout():
	print(pending_points)
	if pending_points > 0:
		#Add 1 to score and pendingPoints; play audio
		score += 1
		pending_points -= 1
		$ScoreUpSound.play()
	elif pending_points < 0:
		#Subtract 1 from score and pendingPoints; play audio
		score -= 1
		pending_points += 1
		if score < 0:
			score = 0
			pending_points = 0
		else:
			$ScoreDownSound.play()
	else:
		$ScoreTimer.stop()
	
	%ScoreValue.text = "x " + str(score)
	%FinalScoreValue.text = %ScoreValue.text

func trigger_next_hint():
	if needs_motion_hint:
		$Hint.text = "Use the arrow keys to move between lily pads."
		$Hint.visible = true
		$HintTimer.start()
		needs_motion_hint = false
	elif needs_fishing_hint:
		$Hint.text = "Move the mouse left or right to aim, then hold the mouse button and release to fish.  Hold longer to fish farther away."
		$Hint.visible = true
		$HintTimer.start()
		needs_fishing_hint = false
	elif needs_habitat_hint:
		$Hint.text = "Different fish like different habitats such as plants and rocks.  See what you can catch!"
		$Hint.visible = true
		$HintTimer.start()
		needs_habitat_hint = false
	elif needs_depletion_hint:
		$Hint.text = "If you fish too long in one spot, the fish will get scared away and you'll have to fish in another habitat for a while."
		$Hint.visible = true
		$HintTimer.start()
		needs_depletion_hint = false

func _on_hint_timer_timeout():
	$Hint.visible = false
