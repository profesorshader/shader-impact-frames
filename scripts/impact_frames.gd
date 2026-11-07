extends Node

@onready var texture_rect_1: TextureRect = $Images/TextureRect1
@onready var texture_rect_2: TextureRect = $Images/TextureRect2

@onready var color_rect: ColorRect = $Postpo/ColorRect

@export var value: float = -4.0
@export var speed: float = 4.0

func _ready() -> void:
	texture_rect_1.visible = true
	texture_rect_2.visible = false

func _process(delta: float) -> void:
	var prev_value = value	
	value = value + speed * delta
	
	# swap background images
	if prev_value <= 0.5 and value > 0.5:
		texture_rect_1.visible = false
		texture_rect_2.visible = true
		color_rect.visible = true

	# change material t value	
	color_rect.material.set_shader_parameter("t", clamp(value, 0.0, 1.0))
