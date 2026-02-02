# Tasks: Succession and Legacy

- [x] **死亡触发逻辑优化**
    - [x] 更新 `LifespanManager` 增加死亡信号发射
    - [x] 确保玩家寿命耗尽时触发转生界面
- [x] **转生选择界面 (Succession Menu)**
    - [x] 实现子嗣过滤与展示
    - [x] 添加“无子嗣”时的 Game Over 引导
    - [x] 实现视觉上的淡入淡出 (Fade Out/In) 转场
- [x] **数据继承与同步**
    - [x] 实现金币、属性点基础资产继承
    - [x] 确保 `InventoryUI` 在继承后重新绑定
    - [x] 确保物理 `Player` 节点数据动态刷新
- [x] **UI 稳定性修复**
    - [x] 修复 `UIManager` 中的语法错误与逻辑嵌套问题
