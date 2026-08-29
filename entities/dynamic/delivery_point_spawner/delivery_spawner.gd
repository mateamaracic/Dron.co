@icon("./delivery_spawner.png")
extends Node3D
class_name DeliveryPointSpawner

@onready var DELIVERY_POINT_SCENE = preload("res://entities/dynamic/delivery_point/delivery_point.tscn")
signal on_delivery()

func random_location():
	var delivery_markers = self.get_children()
	return delivery_markers[randi_range(0, delivery_markers.size() -1)]
	
func spawn_delivery_point():
	var spawn_marker = random_location()
	
	var delivery_point_instance = DELIVERY_POINT_SCENE.instantiate()
	add_child(delivery_point_instance)

	delivery_point_instance.global_position = spawn_marker.global_position
	delivery_point_instance.connect("on_delivery", Callable(self, "package_delivered"))
	
func package_delivered():
	on_delivery.emit()
