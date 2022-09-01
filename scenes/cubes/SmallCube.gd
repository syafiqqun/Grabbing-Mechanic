extends RigidBody

func _ready() -> void:
	add_to_group("dynamic_object")

func disabled_collision():
	$CollisionShape.disabled = true

func enable_collision():
	$CollisionShape.disabled = false

func static_mode():
	mode = RigidBody.MODE_KINEMATIC
	linear_velocity = Vector3.ZERO
	disabled_collision()

func rigid_mode():
	mode = RigidBody.MODE_RIGID
	apply_impulse(Vector3(0, -2, 0), Vector3(0, -4, 0))
	enable_collision()

