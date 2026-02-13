## ADED Requirements: Housing Detection

### Requirement: Automated Validity Check
系统必须能够判定一个封闭空间是否满足 NPC 入住条件。

#### Scenario: Valid House
*   **Given**: 在 Layer 0 建立了一个 6x6 的砖块矩形。
*   **And**: 在 Layer 2 铺满了背景墙。
*   **And**: 内部放置了火把（`housing_light`）、椅子（`housing_comfort`）和桌子（`housing_table`）。
*   **And**: 墙上有一个门（`housing_door`）。
*   **When**: 玩家使用检查模式点击内部。
*   **Then**: 系统返回“此房屋已就绪，等待入住”。

#### Scenario: Invalid Size
*   **When**: 内部空间小于 60 格或大于 749 格。
*   **Then**: 系统返回“房屋空间不合适”。

#### Scenario: Missing Background Wall
*   **When**: 内部空间存在超过 4 格宽度的背景墙空洞。
*   **Then**: 系统返回“背景层不完整”。
