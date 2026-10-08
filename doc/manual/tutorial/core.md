# core tutorial

This tutorial gets you from an empty project to rotating vectors, composing and interpolating orientations, and converting them to Euler angles with `Luna-Flow/quaternion`. It ends with generic code over luna-generic traits and the mistakes that are easy to make. The mathematics is kept light here; the [core design](../design/core.md) derives it.

## Quick start

Add the module to your project:

```sh
moon add Luna-Flow/quaternion@0.2.0
```

Import the package in your `moon.pkg`. The examples also use luna-generic (for generic code) and `moonbitlang/core/math` (for $\pi$):

```moonbit nocheck
import {
  "Luna-Flow/quaternion",
  "Luna-Flow/luna-generic" @lf_alg,
  "moonbitlang/core/math",
}
```

The smallest useful program rotates the x axis by a quarter turn around the z axis:

```moonbit
fn main {
  let quarter_turn = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0)
  println(quarter_turn)
  let (x, y, z) = quarter_turn.rotate((1.0, 0.0, 0.0))
  println("(\{x}, \{y}, \{z})")
}
```

It prints:

```text
0.7071067811865476 + 0i + 0j + 0.7071067811865475k
(2.220446049250313e-16, 1, 0)
```

The x axis lands on the y axis, up to a rounding error of about $2 \times 10^{-16}$ in the first coordinate.

## Everyday tasks

### Build quaternions and multiply them

`Quaternion::from_vec((w, x, y, z))` builds $w + xi + yj + zk$. The usual operators work, and `*` is the Hamilton product. The basis units multiply like $ij = k$ but $ji = -k$, so the order of factors matters:

```moonbit
test "units" {
  let i = @quaternion.Quaternion::from_vec((0, 1, 0, 0))
  let j = @quaternion.Quaternion::from_vec((0, 0, 1, 0))
  let k = @quaternion.Quaternion::from_vec((0, 0, 0, 1))
  inspect(i * j, content="0 + 0i + 0j + 1k")
  inspect(j * i, content="0 + 0i + 0j + -1k")
  inspect(i * i, content="-1 + 0i + 0j + 0k")
  inspect(i * j * k, content="-1 + 0i + 0j + 0k")
}
```

Integer components are exact, which makes `Quaternion[Int]` handy for checking identities. Use `Double` components for rotations.

### Rotate vectors and compose rotations

`from_axis_angle(axis, angle)` gives the unit quaternion of a rotation, and `rotate` applies it to a 3D vector. To apply `first` and then `second`, multiply them as `second * first`, like matrices acting on column vectors:

```moonbit
test "compose rotations" {
  let first = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0) // z, 90 degrees
  let second = @quaternion.from_axis_angle((1.0, 0.0, 0.0), @math.PI / 2.0) // x, 90 degrees
  let both = second * first
  let (x, y, z) = both.rotate((1.0, 0.0, 0.0))
  // x -> y under `first`, then y -> z under `second`
  assert_true(x.abs() < 1.0e-15 && y.abs() < 1.0e-15 && (z - 1.0).abs() < 1.0e-15)
  let (x2, y2, z2) = second.rotate(first.rotate((1.0, 0.0, 0.0)))
  assert_true((x - x2).abs() < 1.0e-15 && (y - y2).abs() < 1.0e-15 && (z - z2).abs() < 1.0e-15)
}
```

`rotate` assumes a unit quaternion. Quaternions built by `from_axis_angle` are unit; call `normalize()` on anything you assembled yourself.

### Undo a rotation and find the rotation between two orientations

The inverse of a unit quaternion is its conjugate. To find the rotation `delta` that takes orientation `from` to orientation `to` (so that `delta * from == to`), divide on the right: `to / from` is $to \cdot from^{-1}$. `left_div` solves the other equation, `from * x == to`, which gives the rotation expressed in the frame of `from`:

```moonbit
test "relative rotation" {
  let from = @quaternion.from_axis_angle((0.0, 1.0, 0.0), 0.3)
  let to = @quaternion.from_axis_angle((1.0, 1.0, 0.0), 1.2)
  let delta = to / from
  assert_true((delta * from - to).square_len() < 1.0e-30)
  let in_from_frame = to.left_div(from)
  assert_true((from * in_from_frame - to).square_len() < 1.0e-30)
  // a unit quaternion's inverse is its conjugate
  assert_true((from.inv() - from.conjugate()).square_len() < 1.0e-30)
}
```

### Compare two rotations

`q` and `-q` describe the same rotation, so `==` is the wrong test for "same orientation". For unit quaternions, $|q \cdot r| = \cos(\theta/2)$ where $\theta$ is the angle between the two orientations:

```moonbit
///|
fn rotation_angle_between(
  q : @quaternion.Quaternion[Double],
  r : @quaternion.Quaternion[Double],
) -> Double {
  let c = q.normalize().dot(r.normalize()).abs()
  2.0 * @math.acos(if c > 1.0 { 1.0 } else { c })
}

test "compare rotations" {
  let q = @quaternion.from_axis_angle((0.0, 0.0, 1.0), 0.5)
  assert_true(q != -q)
  inspect(rotation_angle_between(q, -q), content="0")
  let r = @quaternion.from_axis_angle((0.0, 0.0, 1.0), 0.75)
  assert_true((rotation_angle_between(q, r) - 0.25).abs() < 1.0e-12)
}
```

### Interpolate between orientations

`slerp(q1, q2, t)` moves along the shortest great-circle arc at constant angular speed:

```moonbit
test "slerp steps" {
  let start = @quaternion.id()
  let end = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0)
  for step in 0..<=4 {
    let t = step.to_double() / 4.0
    let (x, y, _) = @quaternion.slerp(start, end, t).rotate((1.0, 0.0, 0.0))
    let degrees = @math.atan2(y, x) * 180.0 / @math.PI
    assert_true((degrees - 22.5 * step.to_double()).abs() < 1.0e-9)
  }
}
```

The x axis turns by $22.5^\circ$ per step, as constant angular speed promises.

### Convert to and from Euler angles

`from_euler(roll, pitch, yaw)` uses the order `"XYZ"` by default, which is $q_X(\text{roll})\,q_Y(\text{pitch})\,q_Z(\text{yaw})$: intrinsic rotations about X, then the new Y, then the new Z. The matching inverse is `to_euler(order="XYZ", external=false)`. The default of `to_euler` is a different convention, extrinsic Z-Y-X, which returns the same three angles in reverse order:

```moonbit
test "euler round trip" {
  let q = @quaternion.from_euler(0.1, 0.2, 0.3)
  let (roll, pitch, yaw) = q.to_euler(order="XYZ", external=false)
  assert_true((roll - 0.1).abs() < 1.0e-12)
  assert_true((pitch - 0.2).abs() < 1.0e-12)
  assert_true((yaw - 0.3).abs() < 1.0e-12)
  let (about_z, _, about_x) = q.to_euler() // extrinsic ZYX
  assert_true((about_z - 0.3).abs() < 1.0e-12 && (about_x - 0.1).abs() < 1.0e-12)
}
```

The k-th angle returned by `to_euler` always belongs to the k-th axis of `order`. Read the [API notes](../api/core.md#quaterniontoeuler) before using other orders: some combinations have known issues.

### Read the components back

`Quaternion` is abstract and has no field accessors. The dot product with a basis quaternion reads one component, and `Debug` shows all four:

```moonbit
///|
fn components(q : @quaternion.Quaternion[Double]) -> (Double, Double, Double, Double) {
  let e = (w, x, y, z) => q.dot(@quaternion.Quaternion::from_vec((w, x, y, z)))
  (e(1.0, 0.0, 0.0, 0.0), e(0.0, 1.0, 0.0, 0.0), e(0.0, 0.0, 1.0, 0.0), e(0.0, 0.0, 0.0, 1.0))
}

test "components" {
  let q = @quaternion.Quaternion::from_vec((0.5, -1.5, 2.0, 4.0))
  debug_inspect(components(q), content="(0.5, -1.5, 2, 4)")
  debug_inspect(q, content="{ r: 0.5, vec: (-1.5, 2, 4) }")
}
```

For finite components the dot product with a basis quaternion returns the component exactly.

## Going further

### Generic code over luna-generic traits

`Quaternion[T]` implements luna-generic's `Ring` whenever `T` does, so ring-generic algorithms accept quaternions. This function computes $x^n$ by repeated squaring for any `Ring`:

```moonbit
///|
fn[R : @lf_alg.Ring] power(x : R, n : Int) -> R {
  if n == 0 {
    @lf_alg.One::one()
  } else {
    let half = power(x, n / 2)
    if n % 2 == 0 { half * half } else { x * half * half }
  }
}

test "generic power" {
  inspect(power(3, 4), content="81")
  let q = @quaternion.Quaternion::from_vec((1, 1, 1, 1))
  inspect(power(q, 3), content="-8 + 0i + 0j + 0k")
  assert_eq(power(q, 3), q.pow_by_int(3))
}
```

Quaternions are not a `Field`, so algorithms that require `Field` (and may assume $ab = ba$) do not accept them. That is deliberate; the [design page](../design/core.md#why-ring-and-not-field) explains why.

### Exact identities over `Int`

Exact components make the norm identity $|pq|^2 = |p|^2|q|^2$ checkable without rounding. Over `Int` it is Euler's four-square identity: a product of two sums of four squares is again a sum of four squares, and the Hamilton product tells you which one:

```moonbit
test "four squares" {
  let p = @quaternion.Quaternion::from_vec((1, 2, 3, 4)) // 1+4+9+16 = 30
  let q = @quaternion.Quaternion::from_vec((2, 0, 1, 5)) // 4+0+1+25 = 30
  let pq = p * q
  inspect(pq, content="-21 + 15i + -3j + 15k")
  assert_eq(pq.square_len(), p.square_len() * q.square_len()) // 900
}
```

Functions that need square roots or trigonometry (`magnitude`, `normalize`, `inv`'s division, `slerp`, Euler conversions) truncate over `Int`; keep `Int` for ring arithmetic.

### Long chains of rotations

Every Hamilton product in `Double` rounds, so the norm of a product of many unit quaternions drifts away from 1, by roughly $n \cdot 10^{-16}$ after $n$ products. `rotate` then scales vectors slightly. Renormalize now and then:

```moonbit
test "renormalize" {
  let step = @quaternion.from_axis_angle((1.0, 2.0, 3.0), 0.001)
  let mut q = @quaternion.id()
  for _ in 0..<100000 {
    q = step * q
  }
  let drift = (q.square_len() - 1.0).abs()
  assert_true(drift < 1.0e-10)
  q = q.normalize()
  assert_true((q.square_len() - 1.0).abs() < 1.0e-15)
}
```

### Performance

All operations work on four scalars and run in constant time, except `pow_by_int`, which uses $O(\log n)$ multiplications. `q.rotate(v)` costs two cross products and is cheaper than computing `q * v * q.inv()` with full Hamilton products. Every function returns a new value; nothing is mutated.

## Common pitfalls

- **`/` changed in 0.2.0.** `q / r` is now $q\,r^{-1}$ (right division). Code written for 0.1.x that relied on `/` computing $r^{-1} q$ must call `q.left_div(r)`.
- **Order of factors.** `a * b` rotates by `b` first. Swapping the factors gives a different rotation unless both turn about the same axis.
- **Non-unit quaternions in `rotate`.** `rotate` does not normalize. For a non-unit $q$ its formula is not $q v q^{-1}$, and the result generally does not even have the length of the input. Normalize first.
- **`==` on rotations.** `q` and `-q` are the same rotation but unequal values. Floating-point results rarely compare equal anyway; compare with a tolerance.
- **Division by zero.** `inv`, `/` and `left_div` divide by $|r|^2$. A zero quaternion gives NaN components over `Double` and a runtime trap over `Int`. `normalize` and `pow_by_T` return the zero quaternion unchanged.
- **`Int` components and transcendental functions.** `magnitude`, `normalize`, `inv` and friends truncate over `Int`; `inv` of anything but a unit is zero.
- **Euler conventions.** `from_euler` defaults to `"XYZ"` and `to_euler` to extrinsic `"ZYX"`. Name both explicitly. Avoid `from_euler` with `"ZYX"` or `"YZX"`, `to_euler` with `"XZY"` extrinsic or `"YZX"` intrinsic, and results near gimbal lock ($|\text{pitch}| \approx 90^\circ$), which have known issues listed in the [API](../api/core.md#quaterniontoeuler). Near gimbal lock `to_euler` also prints a warning line to standard output.
- **Fractional powers.** `pow_by_T` is wrong for quaternions with a negative scalar part; negate the quaternion first when it represents a rotation.
- **Own component types.** `DoubleConvert` is not open for implementation outside this package, so only `Int` and `Double` work with the functions that need it.

## Next steps

- The [core API](../api/core.md) lists every function with its exact signature and edge cases.
- The [core design](../design/core.md) derives the Hamilton product, the rotation formula, slerp and the Euler-angle extraction.
- [luna-generic](https://lunaflow.cn/en/luna-generic/) defines the `Ring`, `Inverse` and `Conjugate` traits used here.
