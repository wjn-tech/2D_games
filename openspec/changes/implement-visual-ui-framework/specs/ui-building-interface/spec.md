# Capability: ui-building-interface

## ADDED Requirements

### Requirement: 建筑蓝图选择界面
玩家必须能够通过可视化界面选择要建造的建筑。

#### Scenario: 打开建造菜单
- **Given** 玩家按下 'G' 键。
- **When** 弹出建造选择菜单。
- **Then** 玩家点击“木屋”图标，菜单关闭，鼠标指针变为木屋的预览虚影。

### Requirement: 资源消耗显示
在选择建筑时，UI 必须清晰显示所需的资源及其当前持有量。

#### Scenario: 资源不足无法建造
- **Given** 建造木屋需要 20 木头，玩家只有 10 个。
- **When** 玩家查看木屋蓝图。
- **Then** 木头需求显示为红色，且“建造”按钮处于禁用状态。
