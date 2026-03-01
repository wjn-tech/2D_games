# Tasks

- [ ] Disable/remove all legacy visual functions in `projectile_base.gd`: `_add_heavy_trail`, `_add_spark_trail`, `_add_ring_pulsate`, `_add_explosion_on_spawn`. <!-- id: 0 -->
- [ ] Migrate `Magic Bolt` identity (`Color(20, 1, 50)`, dense pulse) to `MagicProjectileVisualizer`. <!-- id: 1 -->
- [ ] Migrate `Spark Bolt` identity (`Color(1, 5, 50)`, jittery needle) to `MagicProjectileVisualizer`. <!-- id: 2 -->
- [ ] Migrate `Bouncing Burst` identity (`Color(40, 40, 2)`, ring pulse) to `MagicProjectileVisualizer`. <!-- id: 3 -->
- [ ] Migrate `Chainsaw` identity (`Color(100, 100, 100)`, white-hot sawblade) to `MagicProjectileVisualizer`. <!-- id: 4 -->
- [ ] Migrate `Fireball` identity (`Color(10, 2, 0.1)`, burning core) to `MagicProjectileVisualizer`. <!-- id: 5 -->
- [ ] Migrate `Blackhole` and `TNT` identities to `MagicProjectileVisualizer` with bespoke logic. <!-- id: 6 -->
- [ ] Verify `MagicProjectileVisualizer` fully replaces old visual components (no overlapping trails). <!-- id: 7 -->
