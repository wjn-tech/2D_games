# Capability: industrial-logic-gates

## ADDED Requirements

### Requirement: 基础逻辑门模拟
工业系统必须 (MUST) 支持 AND, OR, NOT 逻辑门。

#### Scenario: 使用 AND 门控制自动门
- **Given** 一个 AND 门的输入 A 连接到压力板，输入 B 连接到开关。
- **When** 玩家同时踩下压力板并打开开关。
- **Then** AND 门输出高电平信号，自动门开启。
