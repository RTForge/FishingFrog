extends Node3D

@onready var bgm_index = AudioServer.get_bus_index("BGM")
@onready var sfx_index = AudioServer.get_bus_index("SFX")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%SensitivitySlider.value = ProjectSettings.get_setting("MouseSensitivity", 0.1)
	%BGMSlider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_index))
	%SFXSlider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_index))
	var window_mode = DisplayServer.window_get_mode()
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		%FullscreenToggle.button_pressed = true
		%FullscreenToggle.text = "on"
	else:
		%FullscreenToggle.button_pressed = false
		%FullscreenToggle.text = "off"
	%HintsToggle.button_pressed = ProjectSettings.get_setting("HintsEnabled", false)
	if %HintsToggle.button_pressed:
		%HintsToggle.text = "on"
	else:
		%HintsToggle.text = "off"
	
	await get_tree().create_timer(1.0).timeout
	var tween = create_tween()
	tween.tween_property(%Fader, "color", Color.TRANSPARENT, 0.5)
	await tween.finished
	%Fader.visible = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_button_pressed():
	%Fader.visible = true
	var tween = create_tween()
	tween.tween_property(%Fader, "color", Color.BLACK, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/level1.tscn")


func _on_settings_button_pressed():
	for child in %ButtonContainer.get_children():
		child.disabled = true
	%SettingsPanel.visible = true

func _on_how_to_play_button_pressed():
	for child in %ButtonContainer.get_children():
		child.disabled = true
	%HowToPlayPanel.visible = true

func _on_about_button_pressed():
	%AboutPanel.visible = true
	for child in %ButtonContainer.get_children():
		child.disabled = true

func _on_exit_button_pressed():
	get_tree().quit()

func _on_sensitivity_slider_value_changed(value):
	ProjectSettings.set_setting("MouseSensitivity", value)

func _on_bgm_slider_value_changed(value):
	AudioServer.set_bus_volume_db(bgm_index, linear_to_db(value))
	AudioServer.set_bus_mute(bgm_index, value == 0)


func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(sfx_index, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_index, value == 0)

func _on_settings_ok_button_pressed():
	%SettingsPanel.visible = false
	for child in %ButtonContainer.get_children():
		child.disabled = false

func _on_how_to_play_ok_button_pressed():
	%HowToPlayPanel.visible = false
	for child in %ButtonContainer.get_children():
		child.disabled = false

func _on_about_ok_button_pressed():
	%AboutPanel.visible = false
	for child in %ButtonContainer.get_children():
		child.disabled = false

func _on_ribbit_timer_timeout():
	$frog/AnimationPlayer.play("Ribbit")
	$RibbitPlayer.pitch_scale = randf_range(0.975, 1.025)
	$RibbitPlayer.play()
	$RibbitTimer.start(randi_range(5, 10))


func _on_fullscreen_toggle_toggled(button_pressed):
		if button_pressed:
			%FullscreenToggle.text = "on"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			%FullscreenToggle.text = "off"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func _on_hints_toggle_toggled(button_pressed):
		if button_pressed:
			%HintsToggle.text = "on"
			ProjectSettings.set_setting("HintsEnabled", true)
		else:
			%HintsToggle.text = "off"
			ProjectSettings.set_setting("HintsEnabled", false)

func _on_credits_label_meta_clicked(meta):
	OS.shell_open(str(meta))


