# Spec: Wand Editor UI

## MODIFIED Requirements

### Requirement: Wand Editor Layout
The wand editor SHALL use a three-column layout with resizable sidebars to improve usability and visibility of wand properties.

#### Scenario: Viewing wand properties
- **WHEN** the user opens the wand editor
- **THEN** the right sidebar SHALL display the wand's current stats and properties using structured UI nodes (icons and labels)
- **AND** the right sidebar SHALL remain visible regardless of the selected edit mode.

#### Scenario: Resizing sidebars
- **WHEN** the user drags the split handle between the left sidebar and the center workspace
- **THEN** the left sidebar width SHALL adjust accordingly.
- **WHEN** the user drags the split handle between the center workspace and the right sidebar
- **THEN** the right sidebar width SHALL adjust accordingly.

#### Scenario: Switching edit modes
- **WHEN** the user clicks the "Visual Design" (外观设计) button in the left sidebar's segmented control
- **THEN** the button SHALL appear highlighted
- **AND** the left sidebar SHALL display the visual module library
- **AND** the center workspace SHALL display the visual grid editor.
- **WHEN** the user clicks the "Logic Programming" (逻辑编程) button in the left sidebar's segmented control
- **THEN** the button SHALL appear highlighted
- **AND** the left sidebar SHALL display the logic node library
- **AND** the center workspace SHALL display the logic graph editor.

### Requirement: Core Logic Preservation
The wand editor SHALL preserve all existing compilation, saving, and testing logic.

#### Scenario: Testing a spell
- **WHEN** the user clicks the "Test Spell" (测试法术) button
- **THEN** the simulation box SHALL appear and execute the spell logic exactly as it did before the UI beautification.
