extends Node
class_name MagicPalette

# --- CORE PALETTE CONSTANTS (User Requirements) ---
# These are the exact high-dynamic range colors required for the "magic feeling".
const FIRE_CORE = Color(10.0, 2.0, 0.1, 1.0)
const FIRE_RIM = Color(1.0, 0.4, 0.0, 1.0) # Complimentary orange
const MAGIC_CORE = Color(0.2, 1.0, 10.0, 1.0)
const MAGIC_RIM = Color(0.0, 0.5, 1.0, 1.0) # Deep blue/cyan

const SPARK_CORE = Color(2.0, 2.0, 10.0, 1.0)
const SPARK_RIM = Color(0.8, 0.8, 1.0, 1.0) # White-blue

const POISON_CORE = Color(2.0, 10.0, 2.0, 1.0) 
const POISON_RIM = Color(0.1, 1.0, 0.2, 1.0)

const VOID_CORE = Color(0.0, 0.0, 0.0, 1.0) # Blackhole
const VOID_RIM = Color(5.0, 0.0, 10.0, 1.0) # Purple rim

# --- HELPER FUNCTIONS ---

static func get_color_for_behavior(behavior: String) -> Color:
	match behavior:
		"fireball", "tnt", "cluster_bomb":
			return FIRE_CORE
		"spark_bolt", "teleport":
			return SPARK_CORE
		"magic_bolt", "magic_arrow", "homing", "bouncing_burst":
			return MAGIC_CORE
		"chainsaw":
			return Color(10.0, 10.0, 10.0, 1.0) # White hot steel
		"blackhole":
			return VOID_RIM
		_:
			return MAGIC_CORE

static func get_rim_color_for_behavior(behavior: String) -> Color:
	match behavior:
		"fireball": return FIRE_RIM
		"magic_bolt": return MAGIC_RIM
		_: return Color(1,1,1,1)
