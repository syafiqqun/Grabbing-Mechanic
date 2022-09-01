extends KinematicBody

#//--------------------------------
#//movement variables
onready var ground_cast = $GroundCast
onready var camera_pivot = $CameraPivot

var mouse_sensitivity = 0.2
var cam_v_down = -80
var cam_v_upper = 45

var full_contact = false

var gravity_vec = Vector3.ZERO

var direction = Vector3.ZERO
var movement = Vector3.ZERO

var h_velocity = Vector3.ZERO

var h_accel = 4
var air_accel = 12
var normal_accel = 6

var normal_speed = 8
var run_speed = 12
var speed = 8
var gravity = 9.8*3

var jump_impulse = 12

var rotation_speed = 0.5
var rotation_sensitivity = 0.08

#//-----------------------------
#//pickable object mechanic

onready var grab_ray_cast = $CameraPivot/Camera/GrabRayCast
onready var position_object_to = $CameraPivot/Position3D

var object_can_grab = false
var carrying_object = false

# object's name
var object_collided

# ref position in the sceneTree
var node_to_grab

# additional info for helper
var object_translation
var ray_cast_point_collided

enum OBJECT_TYPE{NONE = 0, DYNAMIC = 1, STATIC = 2}
var current_object_type = OBJECT_TYPE.NONE

enum CROSSHAIR_STATE{FOCUS = 0, UNFOCUSED = 1, ONCE = 2}
var crosshair = CROSSHAIR_STATE.FOCUS
#//-------------------------------

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func debug_text():
	$Label.text = ""
	$Label.text += "Object Collided >> " + str(object_collided) + "\n"
	$Label.text += "Object Translation >> " + str(object_translation) + "\n"
	$Label.text += "Object Can Grab >> " + str(object_can_grab) + "\n"
	$Label.text += "Carrying Object >>" + str(carrying_object) + "\n"
	$Label.text += "ray cast point collided translation >> " + str(ray_cast_point_collided) + "\n"

func colliding_raycast():
	# check raycast colliding
	if grab_ray_cast.is_colliding():
		object_can_grab = true
		object_collided = grab_ray_cast.get_collider().name
		
		#//additional info for helper,this can be ignore
		object_translation = grab_ray_cast.get_collider().translation
		ray_cast_point_collided = grab_ray_cast.get_collision_normal()
		
		modulate_crosshair(CROSSHAIR_STATE.FOCUS)
		debug_text()
	else:
		object_can_grab = false
		object_collided = null
		
		modulate_crosshair(CROSSHAIR_STATE.UNFOCUSED)
		debug_text()

func grab_and_release():
	#// update colliding raycast
	colliding_raycast()
	
	#// grab and release object
	if Input.is_action_just_pressed("left_click"):
		if carrying_object == false:
			if object_can_grab:
				#// find the node in sceneTree
				var root = get_tree().root
				node_to_grab = root.get_child(0).find_node(str(object_collided))
				
				#// tween the translation
				var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(node_to_grab, "global_translation",
									position_object_to.global_translation, 0.4)
				
				#// object set_mode
				if node_to_grab.is_in_group("dynamic_object"):
					node_to_grab.static_mode()
					carrying_object = true
				else:
					carrying_object = true
		else:
			if node_to_grab.is_in_group("dynamic_object"):
				node_to_grab.rigid_mode()
				carrying_object = false
			else:
				carrying_object = false
	
	#// moving the object with the player
	if carrying_object and node_to_grab != null:
		node_to_grab.global_translation = lerp(node_to_grab.global_translation,
											   position_object_to.global_translation, 0.4)


func modulate_crosshair(p_state):
	#//change cross color
	var children_node = $Crosshair.get_children()
	
	if p_state == CROSSHAIR_STATE.FOCUS:
		for n in children_node:
			n.modulate = Color(1, 0, 0, 0.8)
	if p_state == CROSSHAIR_STATE.UNFOCUSED:
		for n in children_node:
			n.modulate = Color(0, 0, 1, 0.8)


func _process(delta: float) -> void:
	grab_and_release()


func _input(event: InputEvent) -> void:
	
	#//camera movement base on mouse relative position
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		camera_pivot.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		# lock vertical motion
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg2rad(cam_v_down), deg2rad(cam_v_upper))
	
	#// jumping
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_cast.is_colliding()):
		gravity_vec = Vector3.UP * jump_impulse
	
	#// sprinting
	if Input.is_action_pressed("move_forward") and Input.is_action_pressed("run"):
		speed = run_speed
	if Input.is_action_just_released("run"):
		speed = normal_speed


func _physics_process(delta: float) -> void:
	
	#// reset direction
	direction = Vector3()
	
	#// ground check
	if ground_cast.is_colliding():
		full_contact = true
	else:
		full_contact = false
	
	#// applied gravity
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		h_accel = air_accel
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal() * gravity
		h_accel = normal_accel
	else:
		gravity_vec = -get_floor_normal()
		h_accel = normal_accel
	
	#// jumping
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_cast.is_colliding()):
		gravity_vec = Vector3.UP * jump_impulse
	
	#// moving direction
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
		
	if Input.is_action_pressed("move_right"):
		direction = transform.basis.x
#		rotate_y(rad2deg(-rotation_speed * 0.1 * delta))
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
#		rotate_y(rad2deg(rotation_speed * 0.1 * delta))

	
	#// movement smooth and normalized
	direction = direction.normalized()
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_accel * delta)
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y
	
	move_and_slide(movement, Vector3.UP)
