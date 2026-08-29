@icon("./game_master.png")
extends Node
class_name GameMaster

signal delivered_changed(delivered: int)
signal time_changed(time: float)
var packages_delivered := 0:
	set(value):
		delivered_changed.emit(value)
		packages_delivered = value

@export var GAME_TIMER: Timer
@export var TIME_ADD_ON_DELIVERY := 15.0
@export var DRONE: DroneBody3D
@export var INTERFACE: UserInterface
@export var ENVIRONMENT: GameEnvironment
@export var GAME_AREA: PlayerArea3D
@export var SIGNAL_AREA: PlayerArea3D
@export var WIND_AREA: PlayerArea3D
@export var HEADQUARTERS: Headquarters
@export var POINT_SPAWNER: DeliveryPointSpawner
@export var POINTS_OF_INTEREST: Node3D  # roditelj Headquartersa i svih Chargera
@export var CITY_GENERATOR: Node3D      # $Town/CityGenerator

func _ready() -> void:
	_generate_city()

	# game_master_time -> interface
	self.connect("time_changed", Callable(INTERFACE, "set_countdown"))
	# game_master_delivered -> interface
	self.connect("delivered_changed", Callable(INTERFACE, "set_delivered"))
	
	# timer -> drone_die
	GAME_TIMER.connect("timeout", Callable(DRONE, "die").bind("You ran out of time!"))
	
	# drone_charge -> interface
	DRONE.connect("charge_change", Callable(INTERFACE, "set_charge"))
	# drone_death -> interface
	DRONE.connect("on_death", Callable(INTERFACE, "set_death_screen"))
	
	# interface_graphics -> environment
	INTERFACE.connect("graphics_low", Callable(ENVIRONMENT, "set_graphics_low"))
	INTERFACE.connect("graphics_high", Callable(ENVIRONMENT, "set_graphics_high"))
	# interface_saturation -> environment
	INTERFACE.connect("change_saturation", Callable(ENVIRONMENT, "set_saturation"))
	# interface_start -> game_timer
	INTERFACE.connect("on_start", Callable(GAME_TIMER, "start"))
	# interface_start -> drone_movement
	INTERFACE.connect("on_start", Callable(DRONE, "start"))
	
	# point_spawner -> game_master
	POINT_SPAWNER.connect("on_delivery", Callable(self, "deliver"))
	# point_spawner -> headquarters
	POINT_SPAWNER.connect("on_delivery", Callable(HEADQUARTERS, "delivery_state_toggle"))
	
	# headquarters -> point_spawner
	HEADQUARTERS.connect("spawned_package", Callable(POINT_SPAWNER, "spawn_delivery_point"))
	
	# wind_area -> drone_windy
	WIND_AREA.connect("on_player_entered", Callable(DRONE, "set_windy").bind(true))
	WIND_AREA.connect("on_player_exited", Callable(DRONE, "set_windy").bind(false))
	# wind_area -> interface
	WIND_AREA.connect("on_player_entered", Callable(INTERFACE, "set_wind_warning").bind(true))
	WIND_AREA.connect("on_player_exited", Callable(INTERFACE, "set_wind_warning").bind(false))
	# game_area -> drone_die
	GAME_AREA.connect("on_player_exited", Callable(DRONE, "die").bind("The drone lost its signal connection!"))
	GAME_AREA.connect("on_package_exited", Callable(DRONE, "die").bind("The drone lost its package!"))
	# signal_area -> interface
	SIGNAL_AREA.connect("on_player_entered", Callable(INTERFACE, "set_signal_warning").bind(false))
	SIGNAL_AREA.connect("on_player_exited", Callable(INTERFACE, "set_signal_warning").bind(true))
		
func _process(_delta: float) -> void:
	time_changed.emit(GAME_TIMER.time_left)

func _input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func deliver():
	packages_delivered += 1
	GAME_TIMER.start(GAME_TIMER.time_left + TIME_ADD_ON_DELIVERY)

func _generate_city() -> void:
	if not CITY_GENERATOR:
		return
	var reserved: Array = []
	if POINTS_OF_INTEREST:
		for child in POINTS_OF_INTEREST.get_children():
			reserved.append(child.global_position)
	if POINT_SPAWNER:
		for marker in POINT_SPAWNER.get_children():
			reserved.append(marker.global_position)
	CITY_GENERATOR.generate_city(randi(), reserved)
