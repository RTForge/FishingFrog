@tool
class_name Frog extends Node3D

enum FrogState {Aiming, Moving, Charging, Fishing}

@export var current_pad: LilyPad
var current_fish: Fish
@export var state: FrogState = FrogState.Aiming : set = state_changed
signal points_added(points: int)
signal pad_changed(pad: LilyPad)

@export var max_tongue_distance: float
@onready var tongue = $"../Tongue"
@onready var tongue_curve: Curve3D = tongue.curve
@onready var aim_bar: MeshInstance3D = $aim_bar
@onready var anim: AnimationPlayer = $frog/AnimationPlayer
@onready var ribbit: AudioStreamPlayer = $ribbit
@onready var sensitivity: float = ProjectSettings.get_setting("MouseSensitivity", 0.1)
var charge: float
var cursor_pos: Vector3
var angle: float

# Called when the node enters the scene tree for the first time.
func _ready():
	if current_pad:
		global_position = current_pad.global_position
		
func state_changed(new_state):
	if Engine.is_editor_hint():
		return
	match new_state:
		FrogState.Aiming:
			aim_bar.mesh.surface_get_material(0).set_shader_parameter("fill_amount", 1.0);
			aim_bar.visible = true
		FrogState.Moving:
			aim_bar.visible = false
		FrogState.Charging:
			charge = 0.0
			aim_bar.visible = true
		FrogState.Fishing:
			aim_bar.visible = false
			go_fish()
	state = new_state
	
func track_cursor(pos):
	cursor_pos = pos

func _input(event):
	if Engine.is_editor_hint():
		return
	if state == FrogState.Aiming:
		if event is InputEventMouseMotion:
			turn(event.velocity.x)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return

	if state == FrogState.Aiming:
		if Input.is_action_just_released("move_left") and current_pad.left_pad:
			move_to_pad(current_pad.left_pad)
		elif Input.is_action_just_released("move_right") and current_pad.right_pad:
			move_to_pad(current_pad.right_pad)
		elif Input.is_action_just_pressed("move_foward") and current_pad.forward_pad:
			move_to_pad(current_pad.forward_pad)
		elif Input.is_action_just_pressed("move_backward") and current_pad.backward_pad:
			move_to_pad(current_pad.backward_pad)
		elif Input.is_action_just_pressed("tongue_cast") and cursor_pos != null:
			state = FrogState.Charging
	elif state == FrogState.Charging:
		charge += delta
		if charge > 1.0:
			charge = 1.0
			state = FrogState.Fishing
		aim_bar.mesh.surface_get_material(0).set_shader_parameter("fill_amount", charge);
		if Input.is_action_just_released("tongue_cast"):
			state = FrogState.Fishing

func turn(amount: float):
	angle += amount
	global_rotate(Vector3.UP, amount / DisplayServer.window_get_size().x * -sensitivity)

func move_to_pad(pad: LilyPad):
	state = FrogState.Moving
	look_at(pad.global_transform.origin)
	$ribbit.pitch_scale = randf_range(0.975, 1.025)
	$ribbit.play()
	var tween = create_tween()
	tween.tween_property(self, "global_position", pad.global_position, 0.66)
	anim.play("Jump")
	pad_changed.emit(pad)
	await get_tree().create_timer(0.33).timeout
	anim.play_backwards("Jump")
	await tween.finished
	current_pad = pad
	state = FrogState.Aiming
	
func go_fish():
	var cast_pos = await cast_tongue($tongue_origin.global_position)
	await get_tree().create_timer(0.5).timeout
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsPointQueryParameters3D.new()
	query.position = cast_pos
	query.collide_with_areas = true
	query.collision_mask = 2	#Collide with habitat areas only
	var result = space_state.intersect_point(query, 1)
	if result.size() > 0:
		var habitat = result[0]["collider"]
		var fish = habitat.go_fish()
		if fish:
			fish.visible = false
			get_tree().root.add_child(fish)
			current_fish = fish

	await get_tree().create_timer(0.5).timeout
	await reel_tongue()
	state = Frog.FrogState.Aiming
	
func cast_tongue(aim_pos: Vector3) -> Vector3:
	$cast.play()
	tongue.visible = true
	var start_pos = $tongue_origin.global_position
	var start_ref_pos = Vector3(start_pos.x, 0, start_pos.z)
	#var end_pos = start_ref_pos + (aim_pos - start_ref_pos).normalized() * charge * max_tongue_distance
	var end_pos = start_ref_pos + (start_ref_pos - global_position).normalized() * charge * max_tongue_distance
	var tween_speed = (end_pos - start_pos).length() / 10
	tongue_curve.set_point_position(0, start_pos)
	var tween = create_tween()
	tween.tween_method(_tween_tongue_endpoint, start_pos, end_pos, tween_speed)
	tween.parallel().tween_method(_tween_tongue_height, 0.0, 1.0, tween_speed)
	tween.set_ease(Tween.EASE_OUT)
	await tween.finished
	$splash_particles.global_position = end_pos
	$splash_particles.restart()
	$splash.play()
	return end_pos

func reel_tongue():
	var start_pos = tongue_curve.get_point_position(1)
	var end_pos = $tongue_origin.global_position
	var tween = create_tween()
	var tween_speed = (end_pos - start_pos).length() / 4
	tween.tween_method(_tween_tongue_endpoint, start_pos, end_pos, tween_speed)
	tween.parallel().tween_method(_tween_tongue_height, 1.0, 0.0, tween_speed)
	tween.set_ease(Tween.EASE_OUT)
	if current_fish:
		current_fish.global_position = start_pos
		current_fish.visible = true
		tween.parallel().tween_property(current_fish, "global_position", end_pos, tween_speed)
	await tween.finished
	tongue.visible = false
	if current_fish:
		$gulp.play()
		points_added.emit(current_fish.points)
		current_fish.visible = false
		current_fish.queue_free()
		current_fish = null

func _tween_tongue_endpoint(dest: Vector3):
	$"../Tongue".curve.set_point_position(1, dest)

func _tween_tongue_height(height: float):
	$"../Tongue".curve.set_point_in(1, Vector3(0, height, 0))
