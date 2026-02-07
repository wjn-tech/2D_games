extends ItemData
class_name WandItem

@export var wand_data: WandData

func _init():
	# Ensure wand_data exists if created from scratch, though ResourceLoader handles this usually
	if not wand_data:
		wand_data = WandData.new()

# Helper to deep copy the item (including unique wand data)
func duplicate_item() -> WandItem:
	# duplicate(true) tries to duplicate subresources.
	# Since wand_data is a subresource, it should be copied.
	return self.duplicate(true) as WandItem
