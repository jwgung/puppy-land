## How big a body looks for its mass (2026-10-28 user request "무게에 따라 크기가 달라지게": two 1 kg
## balls looked different, a heavier one was not bigger). Bodies of one stuff have one density, so
## the drawn size follows the cube root of the mass: twice the size is 8 times the mass, and equal
## masses look equal. Visual only: the labs keep their bodies, collision shapes and formula models
## (the mesh grows from the body's contact point, ArtJuice.look_scale). No lab needs a clamp: their
## mass ranges stay within a size ratio of 2.8 (0.5-10 kg collision, 2-16 kg friction, 1-20 kg
## lever and pulley), so every order and equality is the cube root's own.
## The buoyancy drum is not here: its size is its volume (큰 통 / 작은 통); its mass is the weight on
## its lid (BuoyancyProps).
class_name MassLook
extends RefCounted


## Size of a body of `mass` against one of `reference` mass of the same stuff: (m / m_ref)^(1/3).
static func factor(mass: float, reference: float) -> float:
	return pow(mass / reference, 1.0 / 3.0)


## Radius of a ball of `mass` (kg) of the stuff whose 1 kg ball has radius `radius_1kg`: it follows
## its own mass only (another ball's mass never changes it; 2026-11-03 playtest).
static func radius(mass: float, radius_1kg: float) -> float:
	return radius_1kg * factor(maxf(mass, 0.01), 1.0)


## How far two balls of radii `a` and `b` resting on one floor must each be drawn along it away from
## each other (negative: towards each other) so that they touch exactly when their centres are `reach`
## apart (the collision lab's model contact, radius_a + radius_b). Resting on the floor, balls of radii
## a and b touch at a horizontal distance 2 sqrt(a b).
static func touching_shift(a: float, b: float, reach: float) -> float:
	return 0.5 * (2.0 * sqrt(a * b) - reach)
