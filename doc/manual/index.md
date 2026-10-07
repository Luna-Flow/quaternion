# quaternion

`quaternion` is the Luna-Flow library for quaternions, the extension of complex numbers that is useful for 3D rotations and orientations. It provides arithmetic, normalization, rotation, interpolation and Euler-angle conversion. Everything lives in one package, `Luna-Flow/quaternion`, under `src`.

## The `Quaternion[T]` type

`Quaternion[T]` stores a real part and a vector part of three components. The type is abstract: build values with the constructors below rather than with a struct literal. The component type `T` is generic, and each operation asks only for the traits it needs, for example `Add` for addition or `@luna-generic.Num` for the identity.

| Constructor | Result |
| --- | --- |
| `Quaternion::from_vec((a, b, c, d))` | $a + bi + cj + dk$ |
| `id()` | The identity $1 + 0i + 0j + 0k$; `Quaternion::default()` returns the same value. |
| `from_axis_angle(axis, angle)` | The rotation by `angle` radians around `axis`, which does not need to be normalized. |
| `from_euler(roll, pitch, yaw, order?)` | The rotation given by Euler angles in radians; `order` defaults to `"XYZ"`. |

## Operations

Quaternions support `+`, `-`, unary `-`, and `*` (the Hamilton product), as well as `/`, `Eq`, `Hash` and `Show`; `to_string` prints the form `a + bi + cj + dk`. The type implements `Conjugate` and `Inverse` from `Luna-Flow/luna-generic`.

| Method | Meaning |
| --- | --- |
| `scale(s)` | Multiplies every component by `s`. |
| `dot(other)` | The dot product of the four components. |
| `square_len()`, `magnitude()` | The squared norm and the norm. |
| `normalize()` | The quaternion scaled to unit length; a zero quaternion is returned unchanged. |
| `map(f)` | Applies `f` to every component, possibly changing the component type. |
| `pow_by_int(n)`, `pow_by_T(x)` | Integer and real powers. |
| `rotate((x, y, z))` | Rotates a 3D vector; the receiver should be a unit quaternion. |
| `to_euler(order?, external?)` | Three Euler angles in radians for the chosen axis order. |

`slerp(q1, q2, t)` interpolates spherically between two rotations. It normalizes both inputs, takes the shorter path, and falls back to normalized linear interpolation when the two rotations are almost equal.

`to_euler` accepts the orders `"XYZ"`, `"XZY"`, `"YZX"` and `"ZYX"` (the default) and returns extrinsic angles unless `external` is `false`. Each combination is also available directly, as `to_euler_external_ZYX`, `to_euler_internal_XYZ` and so on. `from_euler` accepts `"XYZ"`, `"YXZ"`, `"ZYX"`, `"YZX"` and `"ZXY"`. An unsupported order aborts. Near gimbal lock, `to_euler` prints a warning and fixes one of the angles.

## Algebraic structure and division semantics

- `Quaternion[T]` implements `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring` and `Ring` from luna-generic when `T : Ring` (`T` is expected to be commutative, e.g. `Int`, `Double`). Multiplication is the Hamilton product and is **not commutative**.
- `Field` is deliberately **not** implemented: quaternions form a division ring (skew field), and generic code written against `Field` may assume `a * b == b * a`.
- `q / r` is **right division**: `q / r == q * r.inv()`, the solution `x` of `x * r == q`. This is the conventional meaning of `/` in a division ring and keeps `Div` consistent with `Inverse`.
- `q.left_div(r)` is **left division**: `r.inv() * q`, the solution `x` of `r * x == q`.
- `Quaternion::zero()` / `Quaternion::one()` return the additive and multiplicative identities; `q.inv()` and `q.conjugate()` are available as methods.

## Converting through `Double`

Several functions compute square roots and trigonometric functions on `Double`, so they require the component type to implement the `DoubleConvert` trait, which converts a value to and from `Double`. The package implements it for `Double` and `Int`; implement it for another numeric type to use that type with `magnitude`, `normalize`, `slerp` and the Euler-angle functions.

## Example

```moonbit
let axis = (0.0, 0.0, 1.0)
let quarter_turn : Quaternion[Double] = from_axis_angle(axis, @math.PI / 2.0)
let rotated = quarter_turn.rotate((1.0, 0.0, 0.0))
let halfway = slerp(id(), quarter_turn, 0.5)
```

`rotated` is approximately `(0.0, 1.0, 0.0)`, and `halfway` is the rotation by $\pi/4$ around the same axis.

The generated interface `src/pkg.generated.mbti` lists every public signature.
