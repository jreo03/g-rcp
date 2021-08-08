extends StaticBody

var groundmaterial = 0.0
var bumpy = 0.0
var bumpfrequency = 0.0
var bumpfrequencyrandomize = 0.0
var griploss = 0.0
var RCPAddons_skidmark = ""
var RCPAddons_smoke = ""
var RCPAddons_dirt = ""

func _ready():
	if name == "offroad":
		groundmaterial = 1.0
		bumpy = 0.1
		bumpfrequency = 0.5
		bumpfrequencyrandomize = 1.0
		griploss = 0.7
