# Spec: Magic Circuit Logic

## ADDED Requirements

#### Requirement: Graph-Based Processing
The system must support a Directed Acyclic Graph (DAG) where nodes can branch (one input, multiple outputs) or merge.

#### Scenario: Splitter Node
- **Given** a circuit: [Trigger] -> [Splitter] -> (Branch A: [Fireball], Branch B: [Ice Shard])
- **When** the spell is cast
- **Then** two distinct projectiles (one Fire, one Ice) should be emitted simultaneously.

#### Requirement: Sequential Processing
The system must process Attack Materials in the order they are connected in the circuit.

#### Scenario: Modifier Precedence
- **Given** a circuit: [Double Damage] -> [Fireball]
- **When** the spell is cast
- **Then** the [Fireball] should receive the [Double Damage] effect.

#### Scenario: Branching/Looping (Future Proofing)
- **Given** a complex circuit
- **Then** the system should strictly enforce "Left to Right" or "Output flow" to prevent infinite loops, unless specifically designed (e.g., Repeaters).

#### Requirement: Material Effects
Specific materials must provide distinct Logic modifiers.

#### Scenario: Basic Attack Routing
- **Given** an [Iron Ore] (Physical Dmg) and [Ruby] (Fire Dmg)
- **When** connected as [Ruby] -> [Iron Ore] (assuming Ore is projectile source)
- **Then** the resulting projectile should deal Physical + Fire damage.
