part of 'enums.dart';

/// Configuration for continuous physical spring simulations
/// (e.g., snapbacks, active dragging magnets).
///
/// Under-damped springs (where damping is less than critical damping,
/// i.e., damping < 2 * sqrt(mass * stiffness)) will oscillate before
/// coming to rest, creating a high-fidelity visual bounce effect.
@immutable
class SpringPhysicsConfiguration {
  const SpringPhysicsConfiguration({
    this.mass = 1.0,
    this.stiffness = 180.0,
    this.damping = 15.0,
  })  : assert(mass > 0, 'Mass must be positive'),
        assert(stiffness > 0, 'Stiffness must be positive'),
        assert(damping >= 0, 'Damping must be non-negative');

  /// High-fidelity under-damped spring configuration with a premium dynamic feel.
  const SpringPhysicsConfiguration.premium()
      : mass = 1.0,
        stiffness = 220.0,
        damping = 18.0;

  /// Stiff, responsive snap-back spring with minimal overshoot or oscillations.
  const SpringPhysicsConfiguration.stiff()
      : mass = 0.8,
        stiffness = 300.0,
        damping = 25.0;

  /// Gentle, slower spring with a highly fluid, floating behavior.
  const SpringPhysicsConfiguration.gentle()
      : mass = 1.2,
        stiffness = 120.0,
        damping = 12.0;

  /// Mass of the visual card object. Defaults to `1.0`.
  final double mass;

  /// Stiffness of the spring simulation constant. Defaults to `180.0`.
  final double stiffness;

  /// Resistance of the spring movement (damping ratio). Defaults to `15.0`.
  final double damping;

  /// Returns the corresponding Flutter standard [SpringDescription].
  SpringDescription toSpringDescription() => SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SpringPhysicsConfiguration &&
          runtimeType == other.runtimeType &&
          mass == other.mass &&
          stiffness == other.stiffness &&
          damping == other.damping;

  @override
  int get hashCode => Object.hash(mass, stiffness, damping);

  @override
  String toString() => 'SpringPhysicsConfiguration('
      'mass: $mass, stiffness: $stiffness, damping: $damping)';
}
