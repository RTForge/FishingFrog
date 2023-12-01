class_name Habitat extends Area3D

## Fish bones are worth 0 points
@export var chance_fish_bones: float
## Pink fish are worth 1 point
@export var chance_pink_fish: float
## Blue fish are worth 2 points
@export var chance_blue_fish: float
## Green fish are worth 3 points
@export var chance_green_fish: float
## Red fish are worth 5 points
@export var chance_red_fish: float
## Puffer fish are worth -4 points
@export var chance_puffer_fish: float
var chances: Array[float]

var fish_bones = preload("res://scenes/fish_bones.tscn")
var pink_fish = preload("res://scenes/pink_fish.tscn")
var blue_fish = preload("res://scenes/blue_fish.tscn")
var green_fish = preload("res://scenes/green_fish.tscn")
var red_fish = preload("res://scenes/red_fish.tscn")
var puffer_fish = preload("res://scenes/puffer_fish.tscn")
var fish: Array

var chance_multiplier: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	chances.append(chance_pink_fish)
	fish.append(pink_fish)
	chances.append(chance_blue_fish)
	fish.append(blue_fish)
	chances.append(chance_green_fish)
	fish.append(green_fish)
	chances.append(chance_red_fish)
	fish.append(red_fish)
	chances.append(chance_fish_bones)
	fish.append(fish_bones)
	chances.append(chance_puffer_fish)
	fish.append(puffer_fish)

	var total_score: float = 0
	var total_chance: float = 0
	for i in chances.size():
		total_chance += chances[i]
		var tmp_fish = fish[i].instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		total_score += tmp_fish.points * chances[i]
		tmp_fish.queue_free()
	if total_chance > 1.0:
		push_warning("Chance of catching a fish is > 100%")
	print(name, " average score: ", total_score)

func _process(delta):
	#If you stop fishing this habitat, slowly rebuild your chance of catching a fish
	chance_multiplier += 0.01 * delta
	if chance_multiplier > 1.0:
		chance_multiplier = 1.0

func go_fish() -> Fish:
	#Every time you fish, your chances of catching anything get a little smaller
	chance_multiplier -= 0.1
	if chance_multiplier < 0.1:
		chance_multiplier = 0.1
	print("Chance multiplier = ", chance_multiplier)
	
	#Pick a random number between 0 and 1
	var fish_select = randf()
	var min_chance: float = 0
	var max_chance: float = 0
	for i in fish.size():
		#Check each of our chances to see which fish we caught
		var chance: float = chances[i] * chance_multiplier
		max_chance += chance
		if fish_select > min_chance and fish_select < max_chance:
			print("Caught fish")
			return fish[i].instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		min_chance += chance

	print("Caught no fish")
	return null	
