# core API

This page lists every public item of the package `Luna-Flow/quaternion` (source root `src`), grouped by purpose. The [generated interface](../../../src/pkg.generated.mbti) is the authority for signatures. The examples import the package under its default alias `@quaternion` and luna-generic as `@lf_alg`:

```moonbit nocheck
import {
  "Luna-Flow/quaternion",
  "Luna-Flow/luna-generic" @lf_alg,
  "moonbitlang/core/math",
}
```

The mathematics behind the operations is derived in the [core design](../design/core.md); the [core tutorial](../tutorial/core.md) walks through typical tasks.

## The quaternion type

### `Quaternion`

`Quaternion[T]` is the quaternion $w + xi + yj + zk$ with components of type `T`.

```mbti
type Quaternion[T] derive(Eq, Hash, @debug.Debug)
```

A value stores a scalar (real) part $w$ and a vector part $(x, y, z)$. The type is abstract: build values with `Quaternion::from_vec`, `id`, `Quaternion::zero`, `Quaternion::one`, `from_axis_angle` or `from_euler`, and read them through `Quaternion::dot`, `Quaternion::map`, `to_string` or `Debug`. There are no component accessors (see [reading components](../tutorial/core.md#read-the-components-back)).

`T` is not constrained by the type. Each function asks only for the traits it uses: addition needs `Add`, the Hamilton product needs `Mul + Sub + Add`, the luna-generic structure needs `@lf_alg.Ring`, and anything with square roots or trigonometry needs `DoubleConvert`.

The derived `Eq` and `Hash` compare components exactly. `Debug` shows the stored fields:

```moonbit
test "Quaternion debug form" {
  let q = @quaternion.Quaternion::from_vec((1.0, -2.0, 3.0, 4.5))
  debug_inspect(q, content="{ r: 1, vec: (-2, 3, 4.5) }")
  assert_eq(q, @quaternion.Quaternion::from_vec((1.0, -2.0, 3.0, 4.5)))
}
```

> [!NOTE]
> `q` and `-q` describe the same rotation, but they are different quaternions and compare unequal. Compare rotations with `Quaternion::dot` instead (see the [tutorial](../tutorial/core.md#compare-two-rotations)).

## Construction

### `Quaternion::from_vec`

`Quaternion::from_vec((w, x, y, z))` builds $w + xi + yj + zk$.

```mbti
pub fn[T] Quaternion::from_vec((T, T, T, T)) -> Self[T]
```

The first tuple element is the scalar part. No trait is required, so any component type works.

```moonbit
test "Quaternion::from_vec" {
  let q = @quaternion.Quaternion::from_vec((1, 2, 3, 4))
  inspect(q, content="1 + 2i + 3j + 4k")
}
```

### `id`

`id()` returns the identity $1 + 0i + 0j + 0k$.

```mbti
pub fn[T : @luna-generic.Num] id() -> Quaternion[T]
```

It equals `Quaternion::one()` but asks for `Num`, which every luna-generic numeric type (`Int`, `Int64`, `Double`, ...) implements. As a rotation it is the identity rotation.

### `Quaternion::zero`

`Quaternion::zero()` returns the additive identity $0 + 0i + 0j + 0k$.

```mbti
pub fn[T : @luna-generic.Zero] Quaternion::zero() -> Self[T]
```

### `Quaternion::one`

`Quaternion::one()` returns the multiplicative identity $1 + 0i + 0j + 0k$.

```mbti
pub fn[T : @luna-generic.Zero + @luna-generic.One] Quaternion::one() -> Self[T]
```

`zero` and `one` are the luna-generic `Zero` and `One` methods promoted to static methods. They need fewer traits than `id`:

```moonbit
test "Quaternion::zero and one" {
  let z : @quaternion.Quaternion[Int] = @quaternion.Quaternion::zero()
  let o : @quaternion.Quaternion[Int] = @quaternion.Quaternion::one()
  inspect(z, content="0 + 0i + 0j + 0k")
  inspect(o, content="1 + 0i + 0j + 0k")
  assert_eq(o, @quaternion.id())
}
```

### `from_axis_angle`

`from_axis_angle(axis, angle)` returns the unit quaternion of the rotation by `angle` radians around `axis`.

```mbti
pub fn[T : DoubleConvert + Mul + Add + Div] from_axis_angle((T, T, T), T) -> Quaternion[T]
```

The result is $\cos\frac{\theta}{2} + \sin\frac{\theta}{2}\,\hat n$ with $\hat n = \text{axis}/|\text{axis}|$. The axis does not have to be normalized, but it must be non-zero: a zero axis divides by zero and gives NaN components for `Double`. The rotation is counter-clockwise when you look down the axis toward the origin (right-hand rule). Sines, cosines and the axis length are computed in `Double`, so `T` needs `DoubleConvert`.

```moonbit
test "from_axis_angle" {
  let q = @quaternion.from_axis_angle((0.0, 0.0, 2.0), @math.PI / 2.0)
  inspect(q, content="0.7071067811865476 + 0i + 0j + 0.7071067811865475k")
}
```

### `from_euler`

`from_euler(roll, pitch, yaw, order~)` builds a quaternion from three angles in radians.

```mbti
pub fn[T : DoubleConvert + Mul + Add + Sub] from_euler(T, T, T, order? : String) -> Quaternion[T]
```

`order` defaults to `"XYZ"`. Write $q_X(\alpha)$, $q_Y(\alpha)$, $q_Z(\alpha)$ for the rotations by $\alpha$ around the coordinate axes. The accepted orders compute:

| `order` | Result | Reading |
| --- | --- | --- |
| `"XYZ"` (default) | $q_X(\text{roll})\,q_Y(\text{pitch})\,q_Z(\text{yaw})$ | intrinsic X-Y-Z, equal to extrinsic Z-Y-X |
| `"YXZ"` | $q_Y(\text{pitch})\,q_X(\text{roll})\,q_Z(\text{yaw})$ | intrinsic Y-X-Z |
| `"ZXY"` | $q_Z(\text{roll})\,q_X(\text{pitch})\,q_Y(\text{yaw})$ | intrinsic Z-X-Y, angles taken by position |
| `"ZYX"`, `"YZX"` | see the warning below | |

Any other string aborts with `order error. Please check input format and retry`.

```moonbit
test "from_euler" {
  let q = @quaternion.from_euler(0.1, 0.2, 0.3)
  let qx = @quaternion.from_axis_angle((1.0, 0.0, 0.0), 0.1)
  let qy = @quaternion.from_axis_angle((0.0, 1.0, 0.0), 0.2)
  let qz = @quaternion.from_axis_angle((0.0, 0.0, 1.0), 0.3)
  assert_true((q - qx * qy * qz).square_len() < 1.0e-30)
}
```

> [!WARNING]
> Known issues in the current implementation: `"ZYX"` and `"YZX"` return quaternions that are not unit length and do not correspond to any product of three axis rotations, so do not use them. `"YXZ"` assigns the angles by axis (roll about X, pitch about Y, yaw about Z), while `"ZXY"` assigns them by position (the first angle about Z). Prefer `"XYZ"`, or compose `from_axis_angle` rotations yourself.

### `Quaternion::default` (deprecated method form)

`Default::default()` returns `id()`; the method form is deprecated, see [Deprecated](#deprecated).

## Arithmetic

### `Quaternion::add`

`q + r` adds component-wise.

```mbti
pub fn[T : Add] Quaternion::add(Self[T], Self[T]) -> Self[T]
```

### `Quaternion::sub`

`q - r` subtracts component-wise; it is computed as `q + -r`.

```mbti
pub fn[T : Neg + Add] Quaternion::sub(Self[T], Self[T]) -> Self[T]
```

### `Quaternion::neg`

`-q` negates every component.

```mbti
pub fn[T : Neg] Quaternion::neg(Self[T]) -> Self[T]
```

### `Quaternion::mul`

`q * r` is the Hamilton product.

```mbti
pub fn[T : Mul + Sub + Add] Quaternion::mul(Self[T], Self[T]) -> Self[T]
```

In scalar–vector form, $(s_1, \mathbf v_1)(s_2, \mathbf v_2) = (s_1 s_2 - \mathbf v_1\cdot\mathbf v_2,\ s_1\mathbf v_2 + s_2\mathbf v_1 + \mathbf v_1\times\mathbf v_2)$. The product is associative and distributes over `+`, but it is **not commutative**: $qr - rq = 2\,\mathbf v_q \times \mathbf v_r$. For rotations, `q * r` applies `r` first and then `q`.

The four operators are also available as methods (`q.add(r)`, `q.mul(r)`, ...):

```moonbit
test "operators" {
  let q = @quaternion.Quaternion::from_vec((1, 2, 3, 4))
  let r = @quaternion.Quaternion::from_vec((5, 6, 7, 8))
  inspect(q + r, content="6 + 8i + 10j + 12k")
  inspect(q - r, content="-4 + -4i + -4j + -4k")
  inspect(-q, content="-1 + -2i + -3j + -4k")
  inspect(q * r, content="-60 + 12i + 30j + 24k")
  inspect(r * q, content="-60 + 20i + 14j + 32k")
  assert_eq(q.mul(r), q * r)
}
```

### `Quaternion::div`

`q / r` is right division: $q\,r^{-1}$, the solution $x$ of $x\,r = q$.

```mbti
pub fn[T : Add + Mul + Div + Sub] Quaternion::div(Self[T], Self[T]) -> Self[T]
```

It computes $q\,\bar r / |r|^2$ with one division per component and no intermediate inverse. Dividing by the zero quaternion divides by zero in `T`: NaN components for `Double`, a runtime trap for `Int`. Over `Int` every component is truncated by integer division, so the result is only meaningful when the divisions are exact.

> [!IMPORTANT]
> Since 0.2.0, `/` is right division. Before 0.2.0 it computed the left quotient $r^{-1} q$; use `Quaternion::left_div` for that.

### `Quaternion::left_div`

`q.left_div(r)` is left division: $r^{-1} q$, the solution $x$ of $r\,x = q$.

```mbti
pub fn[T : Add + Mul + Div + Sub] Quaternion::left_div(Self[T], Self[T]) -> Self[T]
```

It computes $\bar r\,q / |r|^2$. The two quotients differ by $2\,(\mathbf v_q \times \mathbf v_r)/|r|^2$, so they agree exactly when the vector parts are parallel.

```moonbit
test "right and left division" {
  let q = @quaternion.Quaternion::from_vec((1.0, 2.0, 3.0, 4.0))
  let r = @quaternion.Quaternion::from_vec((5.0, 6.0, 7.0, 8.0))
  inspect(q / r, content="0.40229885057471265 + 0.04597701149425287i + 0j + 0.09195402298850575k")
  inspect(q.left_div(r), content="0.40229885057471265 + 0i + 0.09195402298850575j + 0.04597701149425287k")
  assert_true((q / r * r - q).square_len() < 1.0e-24)
  assert_true((r * q.left_div(r) - q).square_len() < 1.0e-24)
}
```

### `Quaternion::scale`

`q.scale(s)` multiplies every component by the scalar `s`.

```mbti
pub fn[T : Mul] Quaternion::scale(Self[T], T) -> Self[T]
```

Scalars are central in $\mathbb H$, so `q.scale(s)` equals both `q * s` and `s * q` with `s` read as a real quaternion.

### `Quaternion::conjugate`

`q.conjugate()` returns $\bar q = w - xi - yj - zk$.

```mbti
pub fn[T : Neg] Quaternion::conjugate(Self[T]) -> Self[T]
```

It is the luna-generic `Conjugate` method, promoted. Conjugation reverses products: $\overline{qr} = \bar r\,\bar q$.

### `Quaternion::inv`

`q.inv()` returns the two-sided inverse $q^{-1} = \bar q / |q|^2$.

```mbti
pub fn[T : Div + @luna-generic.Num] Quaternion::inv(Self[T]) -> Self[T]
```

It is the luna-generic `Inverse` method, promoted; generic code calls it as `@lf_alg.Inverse::inv(q)`. For a unit quaternion the inverse is the conjugate. The zero quaternion has no inverse: over `Double` the result has NaN components. Over `Int` the factor `1 / |q|^2` is truncated, so `inv` returns zero unless $|q|^2 = 1$.

```moonbit
test "conjugate and inv" {
  let q = @quaternion.Quaternion::from_vec((1.0, 2.0, 3.0, 4.0))
  inspect(q.conjugate(), content="1 + -2i + -3j + -4k")
  inspect(q.inv(), content="0.03333333333333333 + -0.06666666666666667i + -0.1j + -0.13333333333333333k")
  assert_true((q * q.inv() - @quaternion.id()).square_len() < 1.0e-30)
}
```

### `Quaternion::pow_by_int`

`q.pow_by_int(n)` returns $q^n$ for an `Int` exponent.

```mbti
pub fn[T : @luna-generic.Num + Mul + Add + Sub + Div] Quaternion::pow_by_int(Self[T], Int) -> Self[T]
```

`n = 0` gives the identity and a negative `n` gives $(q^{-1})^{|n|}$. The power is computed by repeated squaring with $O(\log |n|)$ multiplications. Powers of one quaternion commute with each other, so the order of the factors does not matter.

### `Quaternion::pow_by_T`

`q.pow_by_T(t)` returns the real power $q^t$ through the polar form.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Div + Eq] Quaternion::pow_by_T(Self[T], T) -> Self[T]
```

Writing $q = |q|(\cos\varphi + \hat n \sin\varphi)$, the result is $|q|^t(\cos t\varphi + \hat n\sin t\varphi)$. The zero quaternion is returned unchanged. A real quaternion ($x = y = z = 0$) uses `@math.pow` on its scalar part, so a negative real part with a non-integer exponent gives NaN.

```moonbit
test "powers" {
  let q = @quaternion.Quaternion::from_vec((2.0, 2.0, 3.0, 4.0))
  inspect(q.pow_by_int(2), content="-25 + 8i + 12j + 16k")
  inspect(q.pow_by_int(-1), content="0.06060606060606061 + -0.06060606060606061i + -0.09090909090909091j + -0.12121212121212122k")
  inspect(q.pow_by_T(0.5), content="1.967811302759747 + 0.508178806879275i + 0.7622682103189125j + 1.01635761375855k")
}
```

> [!WARNING]
> Known issue: `pow_by_T` recovers the angle as $\varphi = \arcsin|\hat{\mathbf v}|$, which lies in $[0, \pi/2]$. It is wrong when the scalar part is negative ($\varphi > \pi/2$): the function then uses $\pi - \varphi$, so for example `q.pow_by_T(1.0)` returns `q` with the sign of its scalar part flipped. Use `pow_by_int` for integer exponents, and negate `q` first (which does not change the rotation) when you need fractional powers of a rotation with a negative scalar part.

## Norms and inner product

### `Quaternion::dot`

`q.dot(r)` is the Euclidean inner product $w_q w_r + x_q x_r + y_q y_r + z_q z_r$ of the four components.

```mbti
pub fn[T : Mul + Add] Quaternion::dot(Self[T], Self[T]) -> T
```

For unit quaternions, $|q\cdot r| = \cos(\theta/2)$ where $\theta$ is the angle of the rotation that takes one orientation to the other.

### `Quaternion::square_len`

`q.square_len()` returns $|q|^2 = w^2 + x^2 + y^2 + z^2 = q\,\bar q$.

```mbti
pub fn[T : Mul + Add] Quaternion::square_len(Self[T]) -> T
```

It needs only `Mul + Add`, so it is exact over `Int` and `BigInt`. The squared norm is multiplicative: $|qr|^2 = |q|^2|r|^2$.

### `Quaternion::magnitude`

`q.magnitude()` returns $|q|$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert] Quaternion::magnitude(Self[T]) -> T
```

The square root is taken in `Double` and converted back with `DoubleConvert::from_double`, which truncates for `Int`.

### `Quaternion::normalize`

`q.normalize()` returns $q / |q|$, the unit quaternion in the direction of `q`.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Div + Eq] Quaternion::normalize(Self[T]) -> Self[T]
```

The zero quaternion is returned unchanged. The result has norm 1 up to rounding. Over `Int` the computation truncates and is not meaningful.

```moonbit
test "norms" {
  let q = @quaternion.Quaternion::from_vec((1.0, 2.0, 3.0, 4.0))
  inspect(q.dot(q), content="30")
  inspect(q.square_len(), content="30")
  inspect(q.magnitude(), content="5.477225575051661")
  inspect(q.normalize(), content="0.18257418583505536 + 0.3651483716701107i + 0.5477225575051661j + 0.7302967433402214k")
  inspect(q.normalize().magnitude(), content="0.9999999999999999")
}
```

## Rotations

### `Quaternion::rotate`

`q.rotate(v)` rotates the 3D vector `v` by the unit quaternion `q`, that is it computes the vector part of $q\,v\,q^{-1}$.

```mbti
pub fn[T : @luna-generic.Num + Sub] Quaternion::rotate(Self[T], (T, T, T)) -> (T, T, T)
```

The implementation uses $\mathbf t = 2\,\mathbf u \times \mathbf v$ and $\mathbf v' = \mathbf v + w\,\mathbf t + \mathbf u \times \mathbf t$ for $q = (w, \mathbf u)$, which needs no division. That formula equals $q v q^{-1}$ only when $|q| = 1$; `rotate` does not normalize for you. The rotation follows the right-hand rule around the axis of `q`.

```moonbit
test "rotate" {
  let q = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0)
  let (x, y, z) = q.rotate((1.0, 0.0, 0.0))
  assert_true((x - 0.0).abs() < 1.0e-15)
  assert_true((y - 1.0).abs() < 1.0e-15)
  assert_true(z == 0.0)
}
```

### `slerp`

`slerp(q1, q2, t)` interpolates spherically between the rotations `q1` and `q2`.

```mbti
pub fn[T : DoubleConvert + @luna-generic.Num + Mul + Add + Div + Eq] slerp(Quaternion[T], Quaternion[T], Double) -> Quaternion[T]
```

Both inputs are normalized first. If their dot product is negative, `q2` is replaced by `-q2` (the same rotation) so the interpolation takes the shorter arc. With $\cos\Omega = q_1\cdot q_2$ the result is

$$
\operatorname{slerp}(q_1, q_2; t) = \frac{\sin\big((1-t)\Omega\big)}{\sin\Omega}\,q_1 + \frac{\sin(t\Omega)}{\sin\Omega}\,q_2 .
$$

When $\cos\Omega > 0.9995$ the function uses normalized linear interpolation instead, to avoid dividing by a tiny $\sin\Omega$. `t = 0` gives `q1` (normalized) and `t = 1` gives `q2` or `-q2`. Values of `t` outside $[0, 1]$ extrapolate along the same great circle.

```moonbit
test "slerp" {
  let a = @quaternion.id()
  let b = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0)
  let half = @quaternion.slerp(a, b, 0.5)
  let expected = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 4.0)
  assert_true((half - expected).square_len() < 1.0e-30)
}
```

### `Quaternion::to_euler`

`q.to_euler(order~, external~)` decomposes the rotation of `q` into three angles in radians.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler(Self[T], order? : String, external? : Bool) -> (T, T, T)
```

`q` is normalized first. `order` names three distinct axes and defaults to `"ZYX"`; `external` defaults to `true`. The k-th returned angle belongs to the k-th axis of `order`:

- extrinsic (`external=true`), order $ABC$ with angles $(a, b, c)$: rotate about the fixed axis $A$ by $a$, then the fixed $B$ by $b$, then the fixed $C$ by $c$, so $q = \pm\,q_C(c)\,q_B(b)\,q_A(a)$;
- intrinsic (`external=false`): rotate about $A$, then about the moved $B$, then the moved $C$, so $q = \pm\,q_A(a)\,q_B(b)\,q_C(c)$.

The supported orders are `"XYZ"`, `"XZY"`, `"YZX"` and `"ZYX"`; any other string aborts with `order error. Please check input format and retry`. The middle angle lies in $[-\pi/2, \pi/2]$ and the outer angles in $(-\pi, \pi]$.

When the sine of the middle angle reaches $|\sin b| \ge 0.9998$ (about $88.85^\circ$), the decomposition is near gimbal lock: the function prints a `UserWarning: Gimbal lock detected...` line to standard output, sets the middle angle to exactly $\pm\pi/2$ and the third angle to $0$.

```moonbit
test "to_euler" {
  let q = @quaternion.from_euler(0.1, 0.2, 0.3) // q_X(0.1) q_Y(0.2) q_Z(0.3)
  let (x, y, z) = q.to_euler(order="XYZ", external=false) // about X, Y, Z
  assert_true((x - 0.1).abs() < 1.0e-12 && (y - 0.2).abs() < 1.0e-12 && (z - 0.3).abs() < 1.0e-12)
  let (z2, y2, x2) = q.to_euler() // extrinsic ZYX: about Z, Y, X
  assert_true((z2 - 0.3).abs() < 1.0e-12 && (y2 - 0.2).abs() < 1.0e-12 && (x2 - 0.1).abs() < 1.0e-12)
}
```

> [!WARNING]
> Known issues in the current implementation:
>
> - `order="XZY"` with `external=true`, and `order="YZX"` with `external=false`, do not compute the named sequence; they return the angles of intrinsic X-Y-Z (in the order X, Y, Z for the first and Z, Y, X for the second). The other six combinations are correct away from gimbal lock.
> - In the gimbal-lock branch the returned angles do not reproduce the input rotation: the first angle is computed from a formula that does not isolate the remaining degree of freedom. Treat results with $|b| \approx \pi/2$ as unreliable.
> - Between $|\sin b| = 0.9998$ and $1$ the middle angle is snapped to $\pm\pi/2$, an error of up to about $0.02$ rad.

### `Quaternion::to_euler_external_XYZ`

`q.to_euler_external_XYZ()` is `q.to_euler(order="XYZ", external=true)`: angles $(a, b, c)$ about X, Y, Z with $q = \pm q_Z(c)\,q_Y(b)\,q_X(a)$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_external_XYZ(Self[T]) -> (T, T, T)
```

### `Quaternion::to_euler_external_XZY`

`q.to_euler_external_XZY()` is `q.to_euler(order="XZY", external=true)`.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_external_XZY(Self[T]) -> (T, T, T)
```

It currently returns the intrinsic X-Y-Z angles $(a, b, c)$ with $q = \pm q_X(a)\,q_Y(b)\,q_Z(c)$, not an X-Z-Y decomposition (see the warning above).

### `Quaternion::to_euler_external_YZX`

`q.to_euler_external_YZX()` is `q.to_euler(order="YZX", external=true)`: angles about Y, Z, X with $q = \pm q_X(c)\,q_Z(b)\,q_Y(a)$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_external_YZX(Self[T]) -> (T, T, T)
```

### `Quaternion::to_euler_external_ZYX`

`q.to_euler_external_ZYX()` is `q.to_euler()`: angles about Z, Y, X with $q = \pm q_X(c)\,q_Y(b)\,q_Z(a)$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_external_ZYX(Self[T]) -> (T, T, T)
```

### `Quaternion::to_euler_internal_XYZ`

`q.to_euler_internal_XYZ()` is `q.to_euler(order="XYZ", external=false)`: angles about X, Y, Z with $q = \pm q_X(a)\,q_Y(b)\,q_Z(c)$. It inverts `from_euler(a, b, c)` with the default order.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_internal_XYZ(Self[T]) -> (T, T, T)
```

### `Quaternion::to_euler_internal_XZY`

`q.to_euler_internal_XZY()` is `q.to_euler(order="XZY", external=false)`: angles about X, Z, Y with $q = \pm q_X(a)\,q_Z(b)\,q_Y(c)$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_internal_XZY(Self[T]) -> (T, T, T)
```

### `Quaternion::to_euler_internal_YZX`

`q.to_euler_internal_YZX()` is `q.to_euler(order="YZX", external=false)`.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_internal_YZX(Self[T]) -> (T, T, T)
```

It currently returns $(c, b, a)$ with $q = \pm q_X(a)\,q_Y(b)\,q_Z(c)$, the reversed intrinsic X-Y-Z angles, not a Y-Z-X decomposition (see the warning above).

### `Quaternion::to_euler_internal_ZYX`

`q.to_euler_internal_ZYX()` is `q.to_euler(order="ZYX", external=false)`: angles about Z, Y, X with $q = \pm q_Z(a)\,q_Y(b)\,q_X(c)$.

```mbti
pub fn[T : @luna-generic.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::to_euler_internal_ZYX(Self[T]) -> (T, T, T)
```

Every intrinsic variant is the extrinsic variant of the reversed order with the result reversed, because $q_A(a)\,q_B(b)\,q_C(c)$ is both intrinsic $ABC$ and extrinsic $CBA$.

## Conversion through `Double`

### `DoubleConvert`

`DoubleConvert` converts a component type to and from `Double`.

```mbti
pub trait DoubleConvert {
  fn to_double(Self) -> Double
  fn from_double(Double) -> Self
}
pub impl DoubleConvert for Int
pub impl DoubleConvert for Double
```

Square roots, trigonometric functions and `@math.pow` are only available on `Double`, so `magnitude`, `normalize`, `from_axis_angle`, `from_euler`, `slerp`, `pow_by_T` and the Euler-angle conversions go through this trait. For `Double` both directions are the identity. For `Int`, `from_double` is `Double::to_int`, which truncates toward zero, so results of these functions over `Int` are truncated.

The trait is declared `pub`, not `pub(open)`, so code outside this package cannot implement it: `Int` and `Double` are the only component types that work with the functions above. You can still call its methods directly:

```moonbit
test "DoubleConvert" {
  let n : Int = @quaternion.DoubleConvert::from_double(2.9)
  inspect(n, content="2")
  inspect(@quaternion.DoubleConvert::to_double(7), content="7")
}
```

## Other methods

### `Quaternion::map`

`q.map(f)` applies `f` to every component, possibly changing the component type.

```mbti
pub fn[T, U] Quaternion::map(Self[T], (T) -> U) -> Self[U]
```

```moonbit
test "map" {
  let q = @quaternion.Quaternion::from_vec((1, 2, 3, 4))
  inspect(q.map(Int::to_double).scale(0.5), content="0.5 + 1i + 1.5j + 2k")
}
```

### `Quaternion::to_string`

`q.to_string()` renders `q` as `w + xi + yj + zk` using `Show` of the components.

```mbti
pub fn[T : Show] Quaternion::to_string(Self[T]) -> String
```

Negative components keep their sign after the plus, as in `1 + -2i + 3j + 4k`. String interpolation `"\{q}"` and `inspect` use the same text.

### `Quaternion::equal`

`q.equal(r)` (the `==` operator) compares the four components exactly.

```mbti
pub fn[T : Eq] Quaternion::equal(Self[T], Self[T]) -> Bool
```

For `Double` components this is IEEE equality: `0.0 == -0.0`, and a quaternion with a NaN component is not equal to itself.

### `Quaternion::hash`

`q.hash()` hashes the four components, consistently with `equal`.

```mbti
pub fn[T : Hash] Quaternion::hash(Self[T]) -> Int
```

## Trait implementations

`Quaternion[T]` implements these traits:

| Trait | Requirement on `T` | Meaning |
| --- | --- | --- |
| `Add`, `Sub`, `Neg` | `Add`; `Neg + Add`; `Neg` | component-wise |
| `Mul` | `Mul + Sub + Add` | Hamilton product |
| `Div` | `Add + Mul + Div + Sub` | right division $q r^{-1}$ |
| `Eq`, `Hash`, `@debug.Debug` | the same trait | derived, component-wise |
| `Show` | `Show` | `w + xi + yj + zk` |
| `Default` | `@lf_alg.Num` | `id()` |
| `@lf_alg.Zero`, `@lf_alg.One` | `Zero`; `Zero + One` | $0$ and $1$ |
| `@lf_alg.AddMonoid` | `AddMonoid` | $(\mathbb H, +, 0)$ |
| `@lf_alg.MulMonoid`, `@lf_alg.Semiring`, `@lf_alg.Ring` | `Ring` | $(\mathbb H, +, \cdot, 0, 1)$ |
| `@lf_alg.Conjugate` | `Neg` | $\bar q$ |
| `@lf_alg.Inverse` | `Div + Num` | $\bar q / \lvert q\rvert^2$ |

The `Ring` instance assumes that multiplication of `T` is commutative, as it is for `Int`, `Int64`, `BigInt`, `Float` and `Double`; the Hamilton product is associative only over a commutative ring of scalars. `@lf_alg.Field` is deliberately **not** implemented, because quaternion multiplication is not commutative and luna-generic's `Field` is meant for commutative fields. `@lf_alg.Num` is not implemented either: quaternions have no `signum`/`abs` with the meaning `Num` expects.

```moonbit
///|
fn[R : @lf_alg.Ring] square_plus_one(x : R) -> R {
  x * x + @lf_alg.One::one()
}

test "generic Ring code" {
  let q = @quaternion.Quaternion::from_vec((0, 1, 0, 0)) // i
  inspect(square_plus_one(q), content="0 + 0i + 0j + 0k") // i^2 + 1 = 0
}
```

## Deprecated

These method forms come from trait implementations and are kept for compatibility. They are deprecated and hidden from the documentation index; the traits themselves stay implemented.

| Deprecated method | Use instead |
| --- | --- |
| `q.not_equal(r)` | `q != r` |
| `q.hash_combine(hasher)` | `Hash::hash_combine(q, hasher)` |
| `q.output(logger)` | `q.to_string()` or `"\{q}"` |
| `Quaternion::default()` | `id()` or `Default::default()` |
| `q.to_repr()` | `Repr(q)` or `@debug.Debug::to_repr(q)` |
