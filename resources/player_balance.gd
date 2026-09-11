class_name PlayerBalance
extends Resource

@export_category("Movement")
@export var run_speed: float = 285.0
@export var acceleration: float = 2200.0
@export var deceleration: float = 2700.0
@export var jump_velocity: float = -570.0
@export var gravity: float = 1650.0
@export var fall_gravity_multiplier: float = 1.22
@export var jump_cut_multiplier: float = 0.48
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.12

@export_category("Combat")
@export var max_hp: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 34.0
@export var dodge_cost: float = 30.0
@export var dodge_speed: float = 650.0
@export var dodge_duration: float = 0.24
@export var dodge_invulnerability: float = 0.19
@export var hurt_invulnerability: float = 0.75
@export var heal_amount: int = 45
@export var heal_time: float = 0.72

