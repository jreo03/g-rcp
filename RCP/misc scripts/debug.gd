extends Control

func _process(delta):	
	if delta>0:
		get_node("container/fps").text = "fps: "+str(1.0/delta)
		get_node("container/important").text = "rpm: "+str(get_parent().get_node("car").get("rpm"))
		get_node("container/important2").text = "gear: "+str(get_parent().get_node("car").get("gear"))
		get_node("container/important3").text = "kph: "+str(int(get_parent().get_node("car").linear_velocity.length()*2.2))
		get_node("container/important4").text = "torque: "+str(get_parent().get_node("car").get("tq"))
		get_node("container/important5").text = "rpmspeed: "+str(get_parent().get_node("car").get("speedrpm"))
		get_node("container/important6").text = "force: "+str(get_parent().get_node("car").get("gforce"))
		get_node("container/important7").text = "turbo psi: "+str(get_parent().get_node("car").get("psi"))
		get_node("sw").rect_rotation = -get_parent().get_node("car").get("steer")*400
