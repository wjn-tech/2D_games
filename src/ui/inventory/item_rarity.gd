class_name ItemRarity

const COMMON = "Common"
const UNCOMMON = "Uncommon"
const RARE = "Rare"
const EPIC = "Epic"
const LEGENDARY = "Legendary"

const COLORS = {
	COMMON: Color("94a3b8"), # Slate-400
	UNCOMMON: Color("4ade80"), # Green-400
	RARE: Color("60a5fa"), # Blue-400
	EPIC: Color("c084fc"), # Purple-400
	LEGENDARY: Color("fbbf24") # Amber-400
}

const GLOW_COLORS = {
	COMMON: Color("94a3b840"),
	UNCOMMON: Color("4ade8040"),
	RARE: Color("60a5fa40"),
	EPIC: Color("c084fc40"),
	LEGENDARY: Color("fbbf2440")
}

static func get_color(rarity: String) -> Color:
	return COLORS.get(rarity, COLORS[COMMON])

static func get_glow_color(rarity: String) -> Color:
	return GLOW_COLORS.get(rarity, GLOW_COLORS[COMMON])
