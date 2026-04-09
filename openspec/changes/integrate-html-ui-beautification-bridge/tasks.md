## 1. Proposal Alignment
- [ ] 1.1 确认首批试点窗口固定为 `InventoryWindow`，避免多窗口并发改造。
- [ ] 1.2 确认本提案仅覆盖“原生项目内嵌 HTML UI”，不包含整游网页导出。

## 2. WebView Embedding PoC
- [ ] 2.1 抽象 `WebUIAdapter` 接口并接入 `UIManager` 调度点。
- [ ] 2.2 使用 `godot_wry` 完成最小可运行 PoC（打开/关闭 Inventory）。
- [ ] 2.3 验证输入焦点与遮挡行为，补充原生 UI 回退逻辑。
- [ ] 2.4 记录平台限制（Linux 依赖、顶层覆盖、透明能力等）。

## 3. Adapter Decision Gate
- [ ] 3.1 按“平台覆盖、包体、性能、开发效率、授权成本”形成插件对比表。
- [ ] 3.2 在 `godot_wry` / `gdcef` / `godot-webview` 之间选定主适配器与备选适配器。

## 4. Implementation (Selected Adapter)
- [ ] 4.1 接入 Inventory 数据快照与交互回传（move/use/drop）。
- [ ] 4.2 建立连接健康检查与异常降级（回退原生窗口）。
- [ ] 4.3 同步视觉令牌（Godot Theme 与 HTML CSS Variables）。

## 5. Validation
- [ ] 5.1 回归：背包开关、拖拽、使用、丢弃结果一致。
- [ ] 5.2 稳定性：断链/超时/错误注入触发自动回退。
- [ ] 5.3 性能：记录 UI 打开耗时、帧时间、内存开销基线。

## 6. Documentation
- [ ] 6.1 补充开发与发布手册（WebView 插件安装、资源组织、启动顺序）。
- [ ] 6.2 补充排障手册（插件加载失败、桥接失败、输入焦点锁死）。

## Parallelization Notes
- 2.x 可先行，3.x 基于 PoC 数据决策主适配器。
- 4.x 在决策门通过后执行，5.x 与 6.x 可部分并行。
