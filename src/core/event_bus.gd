extends Node

# --- 核心事件总线 ---
# 用于跨模块解耦通信。

# 玩家相关
signal player_moved(new_position: Vector2)
signal player_input_enabled(enabled: bool) # 新增：控制玩家输入开关
signal player_health_changed(current: float, max: float)
signal player_layer_changed(new_layer: int)
signal player_data_refreshed # 新增：当继承或转生后刷新玩家数据

# 交互相关
signal interaction_started(target: Node)
signal interaction_finished(target: Node)

# 物品与库存
signal item_collected(item_data: Resource, amount: int)
signal item_hovered(item_name: String, quality_grade: String)
signal item_unhovered
signal inventory_updated
signal experience_gained(amount: float) # 新增：获得经验
signal level_up(new_level: int) # 新增：等级提升

# 战斗与任务
signal enemy_killed(enemy_id: String, faction: String)
signal poi_discovered(poi_name: String)

# 世界与环境
signal time_passed(total_seconds: float)
signal weather_changed(new_weather_type: String)

# 战斗相关
signal combat_started(enemy: Node)
signal combat_finished(enemy: Node, result: Dictionary)
