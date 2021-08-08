extends Control

func _process(delta):	
	if delta>0:
		get_parent().get_node("debug/container/fps").text = "fps: "+str(1.0/delta)
		get_parent().get_node("debug/container/important").text = "rpm: "+str(get_parent().get_node("car").get("rpm"))
		get_parent().get_node("debug/container/important2").text = "gear: "+str(get_parent().get_node("car").get("gear"))
		get_parent().get_node("debug/container/important3").text = "kph: "+str(int(get_parent().get_node("car").linear_velocity.length()*2.2))
		get_parent().get_node("debug/container/important4").text = "torque: "+str(get_parent().get_node("car").get("tq"))
		get_parent().get_node("debug/container/important5").text = "rpmspeed: "+str(get_parent().get_node("car").get("speedrpm"))
		get_parent().get_node("debug/container/important6").text = "force: "+str(get_parent().get_node("car").get("gforce"))
		get_parent().get_node("debug/container/important7").text = "turbo psi: "+str(get_parent().get_node("car").get("psi"))
