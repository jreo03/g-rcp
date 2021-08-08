extends Camera

func _process(delta):
	look_at(get_parent().get_node("car").translation+Vector3(0,2,0),Vector3(0,1,0))
	translation = get_parent().get_node("car").translation+Vector3(0,2,0)
	translate_object_local(Vector3(0,0,7))
	rotate_object_local(Vector3(1,0,0),-0.25)
