extends RayCast

# external (could be adjusted for individual wheels by another script)
var tyre_code = "1150-185-060-14-060"
var roughness = 0.25

var stiffness = 475.0 # Spring stiffness
var elasticity = 10.0 # Spring rebound rate
var damp = 1.0 # Rebound Dampening

# placeholder
var stiffness_struf = 2.5
var elasticity_struf = 75.0
var StrutDistance = 1.0
#---

var stiffness_swaybar = 0.0 # Swaybar Stiffness


var Connection = 0.0 # Connection between the driveshaft and the wheel itself.
var BrakeInfluence = 0.0 # The amount of stopping torque taken from the "BrakeStrength" property when pressing the brake.
var HandbrakeInfluence = 0.0 # The amount of stopping torque taken from the "BrakeStrength" property when pulling the handbrake.
var Camber = 0.0 # The slant angle of the wheel.
var Caster = 0.0 # Steering caster angle.
var Toe = 0.0 # Toe-In Angle
var Rest = 0.5 # Suspension Rest Distance
var Offset = 0.0 # Hub Offset
var StrutOffset = 0.0 # (WIP)
var SteerAngle_Left = 0.0 # Left steering angle
var SteerAngle_Right = 0.0 # Right steering angle
var Suspension_Geometry = 25.0 # Higher numbers causes more negative camber upon compression.
var Differential_Connection = "" # (WIP) Connects the differential to another wheel.
var SwayBar_Connection = "" # Connects the sway bar to another wheel's axle.

var abs_strength = 1.0 # TCS Sensitivity
var tcs_strength = 1.0 # ABS Sensitivity
var esp_strength = 1.0 # ESP Sensitivity

# internal
var grip = int(tyre_code.substr(0,4))
var tyrewidth = int(tyre_code.substr(5,3))
var tyrear = int(tyre_code.substr(9,4))
var rimsize = int(tyre_code.substr(13,2))
var tread = int(tyre_code.substr(16,3))


var wheelsize =  (( float(tyrewidth)*((float(tyrear)*2)/100) + float(rimsize)*25.4 )*0.003269)/2

var q = ((wheelsize/((1*0.003269)/2))*0.003269)/2
var tyrelc = ((wheelsize/((1*0.003269)/2))*q)/125

var lateraldamp = float(tread)*0.0085
var wheelweight = wheelsize
var tyreprofile = float(tread)/10.0
var coefficiency = float(tyrewidth)*0.1
var contact = 8.0
var tyrecompressrate = 0.9
var tyrecompressiongripmultiply = float(tyrewidth)/500.0
var thread = 1.0
var compress = 0.0
var compress2 = 0.0


var rigidity = 60.0
var tyrerigidity = 60.0


# system
var forcedata = Vector2(0,0)
var wv = 0.0
var wv2 = 0.0
var tyrecompressed = 0.0
var tyrecompressedgrip = 0.0
var tyrecompressedscrub = 0.0
var currentgrip = 0.0
var gripscrub = 0.0
var wheelangle = 0.0
var currentcamber = 0.0
var wheelcompression = 0.0
var patch = Vector2(0,0)
var scrub = 0.0
var dist = 0.0
var contactforce = 0.0
var currentconnection = 0.0
var slip = 0.0
var slipy = 0.0
var brokencontact = 0.0
var brokencontactspin = 0.0
var skidspin = 0.0
var skid = 0.0
var skid2 = 0.0

var currentstif = 0.0
var currentelast = 0.0

var wsing = 0.0


# effects
var groundmaterial = 0.0
var bumpy = 0.0
var bumpycurrent = 0.0
var bumpfrequency = 0.0
var bumpfrequencyrandomize = 0.0
var bumpinverted = false
var griploss = 0.0
var currentelasticity = 0.0
var currentstiffness = 0.0

var cast_current = 0.0

func alignAxisToVector(xform, norm):
	xform.basis.y = norm
	xform.basis.x = -xform.basis.z.cross(norm)
	xform.basis = xform.basis.orthonormalized()
	return xform

func refreshtyres():
	grip = int(tyre_code.substr(0,4))
	tyrewidth = int(tyre_code.substr(5,3))
	tyrear = int(tyre_code.substr(9,4))
	rimsize = int(tyre_code.substr(13,2))
	tread = int(tyre_code.substr(16,3))


	wheelsize =  (( float(tyrewidth)*((float(tyrear)*2)/100) + float(rimsize)*25.4 )*0.003269)/2

	q = ((wheelsize/((1*0.003269)/2))*0.003269)/2
	tyrelc = ((wheelsize/((1*0.003269)/2))*q)/125

	lateraldamp = float(tread)*0.0085
	wheelweight = wheelsize
	tyreprofile = float(tread)/10.0
	coefficiency = float(tyrewidth)*0.1
	contact = 8.0
	tyrecompressrate = 0.9
	tyrecompressiongripmultiply = float(tyrewidth)/500.0
	thread = 1.0
	
	if Connection>0:
		get_parent().GearAssistant[2] = wheelsize


func _ready():
	add_exception(get_parent())
	add_exception(get_node("velocity"))
	add_exception(get_node("velocity2"))
	get_node("geometry").translation = cast_to
	get_node("velocity").global_transform.origin = global_transform.origin
	get_node("velocity2").global_transform.origin = get_node("geometry").global_transform.origin


func _physics_process(delta):
	get_node("geometry").visible = get_parent().get("visualisation")
	get_parent().wheels += 1
	get_parent().set("dsweight",float(get_parent().get("dsweight") +Connection))
	get_node("velocity2").global_transform.basis = get_node("axis").global_transform.basis
	get_node("velocity").global_transform.basis = get_node("axis").global_transform.basis
	var rayvelocity = get_node("velocity").global_transform.basis.orthonormalized().xform_inv(get_node("velocity").get_linear_velocity())
	var rayvelocity2 = get_node("velocity2").global_transform.basis.orthonormalized().xform_inv(get_node("velocity2").get_linear_velocity())
	var rayvelocity2velocity = Vector2(rayvelocity2.x,rayvelocity2.z).length()
	get_node("axis").rotation = Vector3(0,0,0)
	get_node("velocity").linear_velocity = -(get_node("velocity").global_transform.origin -  global_transform.origin)*rigidity
	get_node("velocity2").linear_velocity = -(get_node("velocity2").global_transform.origin -  get_node("geometry").global_transform.origin)*tyrerigidity
	get_node("axis/force").translation = Vector3(0,0,0)

	var rotation_za = get_node("axis").rotation_degrees.z
	var w = -((dist-StrutOffset)*Suspension_Geometry)/(translation.x/deg2rad(90.0))
	
	var mcpherson = w/(abs(w)/90.0 +1)
	
	if translation.x>0:
		currentcamber = -mcpherson - Camber + Caster*get_parent().get("steer")
	else:
		currentcamber = -mcpherson + Camber + Caster*get_parent().get("steer")

	get_node("animation").rotation_degrees.z = currentcamber
	
	var wheelinclinement = rotation_za/90.0 +currentcamber/90.0
	if wheelinclinement>0.25:
		wheelinclinement = 0.25
	elif wheelinclinement<-0.25:
		wheelinclinement = -0.25
		
	wheelangle = abs((wheelinclinement -scrub/90.0)/(tyreprofile/10.0))
	
	if wheelangle>1.0:
		wheelangle = 1.0

	compress = 0.0

	var st = 0.0

	if get_parent().get("steer")<0:
		st = get_parent().get("steer")*SteerAngle_Left
	else:
		st = get_parent().get("steer")*SteerAngle_Right
		
	var toe = Toe
	if translation.x<0:
		toe = -toe
		
	rotation_degrees.y = st -toe


#	if not Differential_Connection == "" and not get_parent().get("DiffType") == "":
#		var linkedwheel = get_parent().get_node(Differential_Connection)
#		if get_parent().get("DiffType") == "Open":
#			the = own.parent.children[own["DifferentialConnection"]]["wheelvelocity"]-own["wheelvelocity"]
#			the *= car["DiffScale"]
#			if the<0:
#				the = 0
#			own["currentconnection"] = 1/(the +1)
#		elif car["DiffType"] == "Limited":
#			the = 0
#			own["currentconnection"] = 1/(the +1)
#		elif car["DiffType"] == "Inverted":
#			the = car.children[own["DifferentialConnection"]]["wheelvelocity"]-own["wheelvelocity"]
#			the *= -car["DiffScale"]
#			if the<0:
#				the = 0
#			own["currentconnection"] = 1/(the +1)
#		elif car["DiffType"] == "Steering":
#			if own.localPosition[0]<0:
#				the = 1-(car["steer"]*car["DiffScale"])
#			else:
#				the = 1+(car["steer"]*car["DiffScale"])
#			if the<0:
#				the = 0
#			elif the>1:
#				the = 1
#			own["currentconnection"] = the
#		elif car["DiffType"] == "SteeringInverted":
#			if own.localPosition[0]>0:
#				the = 1-(car["steer"]*car["DiffScale"])
#			else:
#				the = 1+(car["steer"]*car["DiffScale"])
#			if the<0:
#				the = 0
#			elif the>1:
#				the = 1
#			currentconnection = the
#
#		currentconnection *= Connection
#
#	else:
#		currentconnection = Connection

	currentconnection = Connection

	if is_colliding():

		#suspension
		get_node("geometry").global_transform.origin = get_collision_point()
		get_node("axis").global_transform = alignAxisToVector(get_node("axis").global_transform,get_collision_normal())

		bumpfrequency = 0.0
		bumpy = 0.0
		bumpfrequencyrandomize = 0.0
		griploss = 0.0
		groundmaterial = 0.0
		get_parent().wheelsonground += 1
		
		if not get_collider().get("groundmaterial") == null:
			bumpfrequency = get_collider().get("bumpfrequency")
			bumpy = get_collider().get("bumpy")
			bumpfrequencyrandomize = get_collider().get("bumpfrequencyrandomize")
			griploss = get_collider().get("griploss")
			groundmaterial = get_collider().get("groundmaterial")

		if bumpinverted:
			bumpycurrent -= (rayvelocity2velocity*(bumpfrequency*rand_range(1.0-bumpfrequencyrandomize,1.0+bumpfrequencyrandomize)))/100.0
		else:
			bumpycurrent += (rayvelocity2velocity*(bumpfrequency*rand_range(1.0-bumpfrequencyrandomize,1.0+bumpfrequencyrandomize)))/100.0
		if bumpycurrent<0:
			bumpinverted = false
			bumpycurrent = 0
		elif bumpycurrent>bumpy:
			bumpinverted = true
			bumpycurrent = bumpy
					
		get_parent().groundmaterial += groundmaterial

		cast_current = cast_to.y +bumpycurrent

		var scvelo = rayvelocity.y
		if scvelo>0.0:
			scvelo *= damp

		compress2 = (get_node("geometry").translation.y-cast_current -Rest)*currentelast
#		compress2 *= 1.0
		if compress2<0:
			compress2 = 0
			
		if (get_node("geometry").translation.y-cast_current)>Rest :
			compress = (scvelo - compress2)*currentstif
		if compress>0:
			compress = 0
			
		wheelcompression = -compress
		get_node("axis/force").translation.y = -compress
		
		tyrecompressed = (wheelcompression/1000.0)*tyrecompressrate
		tyrecompressed *= 2.0
		tyrecompressed *= 1.0 -wheelangle
		tyrecompressedscrub = (wheelcompression/1000.0)*tyrecompressrate
		tyrecompressedscrub *= 2.0

		if tyrecompressed<0.0:
			tyrecompressed = 0.0
		elif tyrecompressed>tyrelc:
			tyrecompressed = tyrelc

		if tyrecompressedscrub<0.0:
			tyrecompressedscrub = 0.0

		var decline = (tyrecompressed*tyrecompressed)*(0.8/tyrelc) - (0.43/tyrelc)
		
		tyrecompressedgrip = tyrecompressed*2.0 - decline
		
		tyrecompressedgrip *= 0.5
		
		#----------
		
		#forces
		wv2 = wv
		if wv2<0:
			wv2 = -wv2
		if tyrecompressed>0:
			var sliped = ((max(forcedata[0],forcedata[1])/(tyrecompressed*coefficiency))*2.0) -1.0
			
			if sliped<0.0:
				sliped = 0.0
			elif sliped>1.0:
				sliped = 1.0
				
#			print(sliped)

			if get_parent().get("PhysicsLevel")>0:
				currentgrip = (((float(grip)*( (float(tyrewidth)/(float(tyrewidth)/2.0))/1.5 ))/(get_parent().mass/150.0))/(sliped*(roughness*(-(groundmaterial)+1.0)) +1.0)/(griploss+1.0)/1.1)*(tyrecompressedgrip*tyrecompressiongripmultiply)
			else:
				currentgrip = float(grip*0.9)
			gripscrub =  (((float(grip)*( (float(tyrewidth)/(float(tyrewidth)/2.0))/1.5 ))/(get_parent().mass/150.0))/(sliped*(roughness*(-(groundmaterial)+1.0)) +1.0)/(griploss+1.0)/1.1)*(tyrecompressedscrub*tyrecompressiongripmultiply)

#			currentgrip = 800.0
#			gripscrub = 800.0
			
			var limt = coefficiency*(currentgrip/1000.0)
#			limt *= 2.0
			if contactforce>limt:
				contactforce = limt
			elif contactforce<-limt:
				contactforce = -limt
			
			var thectf = contactforce/(get_parent().mass/100.0)
#			thectf = 0.0



			patch.x += rayvelocity2.x/15
			var maxtravel = currentgrip/1000.0
			if patch.x>maxtravel:
				 patch.x = maxtravel
			elif patch.x<-maxtravel:
				 patch.x = -maxtravel
			patch.y += (rayvelocity2.z - (wv*wheelsize)/2.0)/15.0
			if patch.y>maxtravel*2.0:
				 patch.y = 0.0
			elif patch.y<-maxtravel*2.0:
				 patch.y = -0.0
				 
			patch /= abs(wv)/10.0 +1.0


			var distz = (rayvelocity2.z + patch.y) - (( wv +(thectf*1.0))*wheelsize)/2.0
			var distx = rayvelocity2.x + patch.x
			
			var distz3 = abs(rayvelocity2.z - ((wv-(thectf*1.0))*wheelsize)/2.0)
			var distz4 = rayvelocity2.z - ((wv-(thectf*1.0))*wheelsize)/2.0
			
			var distz2 = abs(distz)
			var distx2 = abs(distx)
			
			var wv3 = abs(wv/2.0)
			
			var rolldirt = abs(wv)
			if rolldirt>10.0:
				rolldirt = 10.0
			
			var the_yes = (abs(distz) + abs(distx))*2.5 + rolldirt
			if the_yes>100.0:
				the_yes = 100.0
			
			get_parent().wheelsforce += the_yes
			
			
			slipy = max(distx2,distz2)

			var longimode = abs((rayvelocity2velocity - (wv3*wheelsize)))
			longimode *= 2.0
			
			longimode -= (currentgrip/1000.0)

			if longimode<0:
				longimode = 0
			elif longimode>1:
				longimode = 1

#			print(longimode)

			
			var mass = get_parent().mass/100
			var unita = 100.0*mass
			var unitb = 25.0/1
			var unitc = 1.0
			var unitd = 0.001/(mass/currentgrip)
			var offsettedzw = (currentgrip*wheelweight)/unita
			
			var slip2 = distz3*0.035
			if slip2<0.0:
				slip2 = 0.0
#			if name == "rl":
#				print(slip2)
			
			var thevelo = wv2/(slip2 +1.0)
			
			var offsettedz = (((wv2*1.0)*(lateraldamp/unitb))/(2.0/4.0))*longimode + offsettedzw*(-(longimode)+1)
			var offsettedx = ((thevelo*(lateraldamp/unitb))/(2.0/4.0))
#			var offsettedx = unitd

			offsettedzw *= 2.0

			if offsettedz<unitc/wheelweight:
				offsettedz = unitc/wheelweight
			if offsettedx<unitd/wheelweight:
				offsettedx = unitd/wheelweight

			brokencontactspin = distz3*(thread/(tyrecompressed/contact +1.0)) -(limt*0.1)
			brokencontact = Vector2(distz3,distx).length()*(thread/(tyrecompressed/contact +1.0)) -(limt*0.1)
			skidspin = brokencontactspin
			skid = brokencontact
			skid2 = Vector2(distz2*2.0,distx2*2.0).length()

			if brokencontact<0:
				brokencontact = 0
			elif brokencontact>1:
				brokencontact = 1
			if brokencontactspin<0:
				brokencontactspin = 0
			elif brokencontactspin>1:
				brokencontactspin = 1
				

			var patchdistancefromcenter = (get_node("geometry").global_transform.origin - get_parent().global_transform.origin).length()

			var farx = distx*patchdistancefromcenter
			var farz = distz*patchdistancefromcenter
			farx /= tyrecompressed+1.0
			farz /= tyrecompressed+1.0
			if translation.x>0:
				farx *= -1.0
			if translation.z>0:
				farz *= -1.0
				
			wsing = (farx/2.0) + farz
			
			if wsing<sliped:
				wsing = sliped
			elif wsing>1.0/(groundmaterial +1.0):
				wsing = 1.0/(groundmaterial +1.0)
				
#			print(wsing)
				

			var method1 = [Vector2(distz2,distx2).length(),Vector2(distz3,distx2).length()]
			var method2 = [distz2 + distx2 + offsettedz,distz3 + distx2 + offsettedx]

			var dampz = 0.0
			var dampx = 0.0

			if get_parent().get("PhysicsLevel") == 2 or get_parent().get("hb"):
				dampz = method1[0]*(-(wsing)+1.0) + method2[0]*wsing
				dampx = method1[1]*(-(wsing)+1.0) + method2[1]*wsing
			else:
				dampz = method1[0]
				dampx = method1[1]

			if dampx<0:
				dampx = 0

			if dampz<0:
				dampz = 0

			var dampw = dampx + dampz
			
			var dampoverall = Vector2(dampz,dampx).length()
			var amountz = distz/(dampz/offsettedz +1) /offsettedz
			var amountzw = distz/(dampw/offsettedzw +1) /offsettedzw
			var amountx = distx/(dampx/offsettedx +1) /offsettedx
			forcedata = [abs(distx),abs(distz)]
			if get_parent().get("PhysicsLevel")<2:
				amountx -= rotation.y*sliped
			var longitudinal = amountz*(currentgrip*2.0)
			var longitudinalw = amountzw*(currentgrip*2.0)
			var lateral = amountx*(currentgrip*2.0)
			var lateralscrub = rayvelocity2.x*(gripscrub*2.0)
			
			get_node("axis/force").translation.x = -lateral/2.0
			get_node("axis/force").translation.z = -longitudinal/2.0
			
			scrub = lateralscrub/(float(tyrewidth)*75.0)
			if scrub<-90.0:
				scrub = -90.0
			elif scrub>90.0:
				scrub = 90.0
			
			scrub /= (abs(scrub)*deg2rad(1.0) ) +1

			wv += (longitudinalw/wheelweight)/50.0

		#------

		var h = skid*0.5 -wv2*(lateraldamp/10.0) -0.5
		if h>1:
			h = 1
		elif h<0:
			h = 0
		get_parent().set("skidding",get_parent().get("skidding")+h)

		var h2 = skid2*0.5 -wv2*(lateraldamp/10.0) -0.75
		if h2<0:
			h2 = 0
		get_parent().set("skidding2",get_parent().get("skidding2")+h2)

		#debug
		get_node("geometry/compress").scale = Vector3(0.01,tyrecompressed/0.5,0.01)
		get_node("geometry/compress").translation.y = get_node("geometry/compress").scale.y/2
		get_node("geometry/longi").scale = Vector3(0.01,0.01,get_node("axis/force").translation.z/500.0)
		get_node("geometry/longi").translation.z = get_node("geometry/longi").scale.z/2.0
		get_node("geometry/lateral").scale = Vector3(get_node("axis/force").translation.x/500.0,0.01,0.01)
		get_node("geometry/lateral").translation.x = get_node("geometry/lateral").scale.x/2.0
		
		get_node("geometry/compress").translation.y -= wheelsize/2
		get_node("geometry/lateral").translation.y = -wheelsize/2
		get_node("geometry/longi").translation.y = -wheelsize/2

	else:
		cast_current = cast_current
		wheelcompression = 0.0
		tyrecompressed = 0.0
		get_node("geometry").translation = cast_to

	dist = abs(cast_current-get_node("geometry").translation.y)

	get_node("geometry/compress").visible = is_colliding()
	get_node("geometry/lateral").visible = is_colliding()
	get_node("geometry/longi").visible = is_colliding()
	
	if not SwayBar_Connection == "":
		var linkedwheel = get_parent().get_node(SwayBar_Connection)
		var rolldist = dist - linkedwheel.get("dist")
		if rolldist<0.0:
			rolldist = 0.0
		currentelast = elasticity*(rolldist*stiffness_swaybar +1)
		currentstif = stiffness*(rolldist*stiffness_swaybar +1)
	else:
		currentelast = elasticity
		currentstif = stiffness

	get_node("geometry").translation.y += wheelsize/2 -(tyrecompressed*0.0025)
	
	if translation.x>0:
		get_node("geometry").translation.x += Offset
	else:
		get_node("geometry").translation.x -= Offset
	
	#wv manipulation
	contactforce = 0.0
	#brake
	var brslip = slipy
	brslip -= get_parent().get("ABS")[1]
	if brslip<0:
		brslip = 0
	elif get_parent().get("brake")>0.5 and get_parent().get("ABS")[4] and rayvelocity2velocity>get_parent().get("ABS")[2]:
		get_parent().set("absflashed", true)
	
	var absenabled = false
	
	if rayvelocity2velocity>get_parent().get("ABS")[2]:
		absenabled = get_parent().get("ABS")[4]
			
	var br = 0.0
			
	if absenabled:
		var brakae = get_parent().get("brake")
		if brakae>get_parent().get("ABS")[3]:
			 brakae = get_parent().get("ABS")[3]
		br = brakae*(-(brslip*(get_parent().get("ABS")[0]))+1)
	else:
		br = get_parent().get("brake")

	var brake = (br*BrakeInfluence)+(get_parent().get("handbrake")*HandbrakeInfluence)
		
	var espb = 0.0
		
	if translation.x>0.0:
		espb = (get_parent().angular_velocity.y)*esp_strength -get_parent().get("ESP")[1]
	else:
		espb = (-get_parent().angular_velocity.y)*esp_strength -get_parent().get("ESP")[1]

	if espb<0:
		espb = 0
	elif espb>(get_parent().get("ESP")[0]*get_parent().get("ESP")[2]):
		espb = (get_parent().get("ESP")[0]*get_parent().get("ESP")[2])
	elif espb>0 and get_parent().get("ESP")[2]:
		get_parent().set("espflashed", true)

	var tcs = slipy*((get_parent().get("TCS")[0]*tcs_strength)*get_parent().get("TCS")[2]) -get_parent().get("TCS")[1]
	if tcs<0:
		tcs = 0
	elif tcs>0 and get_parent().get("TCS")[2]:
		get_parent().set("tcsflashed", true)

	brake += espb +tcs

	if brake>1:
		brake = 1
	
	if brake>0.05:
		var bd = abs(wv/(get_parent().get("BrakeStrength")*brake))
		if wv>get_parent().get("BrakeStrength")*brake or wv<-get_parent().get("BrakeStrength")*brake:
			wv -= wv/(bd +1)
		else:
			wv = 0
	#-----
	
	#driveshaft
	var tvd = (get_parent().get("rpm")/get_parent().get("ratio") - wv)

	var tvd2 = abs(tvd)

	var clutchon = get_parent().get("clutchon")*get_parent().get("clutchon")

	if not get_parent().get("gear") == 0:
		var css = get_parent().get("ClutchStability")/1.0
		var dss = get_parent().get("DriveShaftStability")/1.0
		
		var rat = abs(get_parent().get("ratio"))
			
		if rat>get_parent().get("StabilityThreshold"):
			rat = get_parent().get("StabilityThreshold")
		
		css *= rat/100.0
		dss *= rat/100.0
			
		var bite1 = tvd/css
		var bite2 = tvd/dss
		if bite1>1.0:
			bite1 = 1.0
		elif bite1<-1.0:
			bite1 = -1.0
		if bite2>get_parent().get("BiteStrength"):
			bite2 = get_parent().get("BiteStrength")
		elif bite2<-get_parent().get("BiteStrength"):
			bite2 = -get_parent().get("BiteStrength")
		bite1 *= clutchon
		bite2 *= clutchon
		var wforce = 0.0
		if get_parent().get("dsweightrun")>0:
			if get_parent().get("ratio")>0:
				get_parent().set("resistance",get_parent().get("resistance") -((bite1*(600.0*get_parent().get("ClutchGrip")))*currentconnection)/get_parent().get("dsweightrun"))
			else:
				get_parent().set("resistance",get_parent().get("resistance") +((bite1*(600.0*get_parent().get("ClutchGrip")))*currentconnection)/get_parent().get("dsweightrun"))
			wforce = (bite2*(get_parent().get("torquedrag")*(get_parent().get("DriveShaftGrip")/wheelweight)))*((currentconnection*2.0)/get_parent().get("dsweightrun") )
		wv += wforce
#		print(wforce)
		contactforce += wforce
		var tvddebug = (get_parent().get("speedrpm")/get_parent().get("ratio") - wv)
		tvddebug = tvddebug*currentconnection
		var bitedebug = tvddebug*10.0
		if get_parent().get("ratio")>0.0:
			get_parent().set("resistance2",get_parent().get("resistance2") - bitedebug)
		else:
			get_parent().set("resistance2",get_parent().get("resistance2") + bitedebug)
	#---------------
	

	get_parent().apply_impulse(get_node("geometry").global_transform.origin-get_parent().global_transform.origin,(get_node("axis/force").global_transform.origin-global_transform.origin)/get_parent().mass)
	
	# animations
	get_node("animation").global_transform.origin = get_node("geometry").global_transform.origin
	get_node("animation").translation.y += cast_to.y-cast_current
	get_node("animation/spinning").rotation_degrees.x += wv*wheelsize
	
