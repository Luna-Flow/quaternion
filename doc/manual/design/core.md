# core design

This page explains the mathematics that `Luna-Flow/quaternion` implements and why its API has the shape it has. Every formula below is the one the code in [`src/quaternion.mbt`](../../../src/quaternion.mbt) evaluates; where the implementation deviates from the mathematics, the deviation is stated.

## Design goal

The package gives MoonBit one quaternion type, `Quaternion[T]`, that serves two audiences:

- algebraic code, which wants $\mathbb H$ as a ring over an exact or approximate scalar type and uses it through the luna-generic traits;
- geometric code, which wants unit quaternions as 3D rotations: build them from an axis and an angle or from Euler angles, compose, apply, interpolate and decompose them.

Both are served by the same generic type. Each operation asks only for the traits of `T` it needs, so ring arithmetic works over `Int` exactly, while the operations that need square roots or trigonometry go through `Double`.

## Constraints

- The only Luna-Flow dependency is luna-generic 0.3.3, which provides algebraic traits (`Ring`, `Inverse`, `Conjugate`, `Field`, ...) but no analytic ones: there is no trait for square roots or trigonometric functions.
- luna-generic's `Field` is commutative, while $\mathbb H$ is not.
- MoonBit traits have only the `Self` parameter, so "a scalar type with `sqrt` and `sin`" cannot be expressed as a relation between `T` and another type; it has to be a trait on `T` itself.
- Since MoonBit 0.10, trait implementations do not become methods unless they are promoted explicitly.
- The type is used in rotation-heavy code, so the common operations must be branch-free and allocation-light: no `Result`, no checks on unit length.

## Mathematical background

### Quaternions as a real algebra

The quaternions $\mathbb H$ are the 4-dimensional real vector space with basis $1, i, j, k$,

$$
q = w + x\,i + y\,j + z\,k, \qquad w, x, y, z \in \mathbb R,
$$

with a bilinear multiplication fixed by Hamilton's relations[^hamilton]

$$
i^2 = j^2 = k^2 = ijk = -1 .
$$

[^hamilton]: W. R. Hamilton, "On quaternions; or on a new system of imaginaries in algebra", 1843. The relations are the ones he carved into Brougham Bridge in Dublin.

We write $q = (w, \mathbf u)$ with the scalar part $w$ and the vector part $\mathbf u = (x, y, z)$, and identify $\mathbb R^3$ with the pure quaternions $\{(0, \mathbf u)\}$. `Quaternion[T]` stores exactly this pair: a field `r` for $w$ and a triple `vec` for $\mathbf u$. Real numbers $(s, \mathbf 0)$ commute with everything, because the multiplication is $\mathbb R$-bilinear.

### Products of the units

Everything about the product follows from the four relations. Multiply $ijk = -1$ on the right by $k$ and use $k^2 = -1$:

$$
\begin{aligned}
ijk\,k &= -k \\
-ij &= -k \\
ij &= k .
\end{aligned}
$$

Multiply $ijk = -1$ on the left by $i$ and use $i^2 = -1$: $-jk = -i$, so $jk = i$. The reversed products follow from these two:

$$
\begin{aligned}
ji &= j\,(jk) = j^2 k = -k, \\
kj &= (ij)\,j = i\,j^2 = -i, \\
ik &= i\,(ij) = i^2 j = -j, \\
ki &= (ij)\,i = i\,(ji) = -ik = j .
\end{aligned}
$$

So the units multiply like the cross product of the standard basis, with an extra $-1$ on the diagonal:

| $\cdot$ | $i$ | $j$ | $k$ |
| --- | --- | --- | --- |
| $i$ | $-1$ | $k$ | $-j$ |
| $j$ | $-k$ | $-1$ | $i$ |
| $k$ | $j$ | $-i$ | $-1$ |

The eight elements $\pm 1, \pm i, \pm j, \pm k$ form the quaternion group $Q_8$, which can be realized by $2\times 2$ complex matrices.[^q8] The multiplication of $Q_8$ is associative, and by bilinearity so is the product of $\mathbb H$.

[^q8]: For example $1 \mapsto I$, $i \mapsto \begin{pmatrix} i & 0 \\ 0 & -i\end{pmatrix}$, $j \mapsto \begin{pmatrix} 0 & 1 \\ -1 & 0\end{pmatrix}$, $k \mapsto \begin{pmatrix} 0 & i \\ i & 0\end{pmatrix}$. These matrices satisfy Hamilton's relations, and matrix multiplication is associative.

### The Hamilton product

Expanding $p = w_1 + x_1 i + y_1 j + z_1 k$ times $q = w_2 + x_2 i + y_2 j + z_2 k$ term by term with the table gives

$$
\begin{aligned}
pq ={} & (w_1 w_2 - x_1 x_2 - y_1 y_2 - z_1 z_2) \\
 &+ (w_1 x_2 + x_1 w_2 + y_1 z_2 - z_1 y_2)\, i \\
 &+ (w_1 y_2 - x_1 z_2 + y_1 w_2 + z_1 x_2)\, j \\
 &+ (w_1 z_2 + x_1 y_2 - y_1 x_2 + z_1 w_2)\, k .
\end{aligned}
$$

The same product is clearer in scalar–vector form. For two pure quaternions $\mathbf a$ and $\mathbf b$, the squares of the units contribute $-a_1 b_1 - a_2 b_2 - a_3 b_3$, and the mixed terms pair up, for example $a_1 b_2\, ij + a_2 b_1\, ji = (a_1 b_2 - a_2 b_1)k$. Hence

$$
\mathbf a\,\mathbf b = -\,\mathbf a\cdot\mathbf b + \mathbf a\times\mathbf b .
$$

With bilinearity and the fact that scalars commute,

$$
\begin{aligned}
(s_1, \mathbf v_1)(s_2, \mathbf v_2) &= s_1 s_2 + s_1\mathbf v_2 + s_2\mathbf v_1 + \mathbf v_1\mathbf v_2 \\
&= \big(s_1 s_2 - \mathbf v_1\cdot\mathbf v_2,\ \ s_1\mathbf v_2 + s_2\mathbf v_1 + \mathbf v_1\times\mathbf v_2\big).
\end{aligned}
$$

This is literally the `Mul` implementation: the scalar part is `self.r * other.r - dot(self.vec, other.vec)` and the vector part is `cross(self.vec, other.vec)` plus the two scaled vectors.

Swapping the factors only flips the sign of the cross product, so

$$
pq - qp = 2\,\mathbf v_1 \times \mathbf v_2 ,
$$

and two quaternions commute exactly when their vector parts are parallel. In particular $\mathbb H$ is not commutative: $ij = k$ but $ji = -k$.

The derivation used that the components commute with each other ($s_1\mathbf v_2 = \mathbf v_2 s_1$ and so on). The generic implementation therefore assumes that `T` has a commutative multiplication, which holds for every numeric type luna-generic provides.

### Conjugate and norm

The conjugate is $\bar q = (w, -\mathbf u)$. Multiplying a quaternion by its conjugate leaves a real number, because the cross product of parallel vectors vanishes:

$$
q\bar q = \big(w^2 + \mathbf u\cdot\mathbf u,\ -w\mathbf u + w\mathbf u - \mathbf u\times\mathbf u\big) = \big(w^2 + x^2 + y^2 + z^2,\ \mathbf 0\big) = |q|^2 ,
$$

and in the same way $\bar q q = |q|^2$. `Quaternion::square_len` computes this $|q|^2$, and `Quaternion::dot` is the inner product of $\mathbb R^4$ whose norm it is.

Conjugation reverses products. With $p = (s_1, \mathbf v_1)$ and $q = (s_2, \mathbf v_2)$,

$$
\begin{aligned}
\overline{pq} &= \big(s_1 s_2 - \mathbf v_1\cdot\mathbf v_2,\ -s_1\mathbf v_2 - s_2\mathbf v_1 - \mathbf v_1\times\mathbf v_2\big), \\
\bar q\,\bar p &= \big(s_2 s_1 - \mathbf v_2\cdot\mathbf v_1,\ -s_2\mathbf v_1 - s_1\mathbf v_2 + \mathbf v_2\times\mathbf v_1\big),
\end{aligned}
$$

and the two agree because $\mathbf v_2\times\mathbf v_1 = -\mathbf v_1\times\mathbf v_2$. So $\overline{pq} = \bar q\,\bar p$.

The norm is multiplicative. Using associativity, $\overline{pq} = \bar q\bar p$, and the fact that the real number $|q|^2$ commutes with $p$:

$$
\begin{aligned}
|pq|^2 &= (pq)\,\overline{(pq)} = p\,(q\bar q)\,\bar p \\
&= p\,|q|^2\,\bar p = |q|^2\,p\bar p = |p|^2\,|q|^2 .
\end{aligned}
$$

Over the integers this is Euler's four-square identity, which the [tutorial](../tutorial/core.md#exact-identities-over-int) checks with `Quaternion[Int]`.

### Inverse and the two divisions

If $q$ is not zero, then $|q|^2 > 0$, and $q\bar q = \bar q q = |q|^2$ shows that

$$
q^{-1} = \frac{\bar q}{|q|^2}
$$

is a two-sided inverse. This is the `Inverse` implementation: the conjugate scaled by `one() / square_len()`. Every non-zero quaternion is invertible, so $\mathbb H$ is a *division ring* (a skew field). It is not a field, because it is not commutative.

Without commutativity, "$q$ divided by $r$" has two meanings, one for each side on which the unknown sits:

$$
\begin{aligned}
x\,r = q &\iff x = q\,r^{-1} && \text{(right division, } q / r\text{)}, \\
r\,x = q &\iff x = r^{-1} q && \text{(left division, } q\text{.left\_div}(r)\text{)}.
\end{aligned}
$$

The implementation avoids forming $r^{-1}$ and divides once at the end. With $q = (s_q, \mathbf v_q)$, $r = (s_r, \mathbf v_r)$ and $\bar r = (s_r, -\mathbf v_r)$, the scalar–vector product gives

$$
\begin{aligned}
q\,r^{-1} &= \frac{q\,\bar r}{|r|^2} = \frac{\big(s_q s_r + \mathbf v_q\cdot\mathbf v_r,\ \ s_r\mathbf v_q - s_q\mathbf v_r - \mathbf v_q\times\mathbf v_r\big)}{|r|^2}, \\
r^{-1} q &= \frac{\bar r\,q}{|r|^2} = \frac{\big(s_q s_r + \mathbf v_q\cdot\mathbf v_r,\ \ s_r\mathbf v_q - s_q\mathbf v_r - \mathbf v_r\times\mathbf v_q\big)}{|r|^2},
\end{aligned}
$$

which are the `Div` implementation (with `c = cross(q.vec, r.vec)`) and `Quaternion::left_div` (with `c = cross(r.vec, self.vec)`). The quotients have the same scalar part and differ by

$$
q\,r^{-1} - r^{-1} q = -\frac{2\,\mathbf v_q\times\mathbf v_r}{|r|^2}.
$$

**Example.** Take $q = 1 + 2i + 3j + 4k$ and $r = 5 + 6i + 7j + 8k$. Then $|r|^2 = 174$, $s_q s_r + \mathbf v_q\cdot\mathbf v_r = 5 + 12 + 21 + 32 = 70$, $s_r\mathbf v_q - s_q\mathbf v_r = (4, 8, 12)$ and $\mathbf v_q\times\mathbf v_r = (-4, 8, -4)$, so

$$
\begin{aligned}
q / r &= \tfrac{1}{174}\big(70 + 8i + 0j + 16k\big) \approx 0.4023 + 0.0460\,i + 0.0920\,k, \\
q.\mathrm{left\_div}(r) &= \tfrac{1}{174}\big(70 + 0i + 16j + 8k\big) \approx 0.4023 + 0.0920\,j + 0.0460\,k .
\end{aligned}
$$

The [API page](../api/core.md#quaternionleft_div) checks these values and both defining equations.

### Unit quaternions and rotations

A unit quaternion ($|q| = 1$) can be written

$$
q = \Big(\cos\tfrac{\theta}{2},\ \sin\tfrac{\theta}{2}\,\mathbf n\Big), \qquad |\mathbf n| = 1 ,
$$

which is exactly what `from_axis_angle(axis, angle)` returns, with $\mathbf n$ the normalized axis. For unit $q$ we have $q^{-1} = \bar q$. Consider the map $\mathbf v \mapsto q\,\mathbf v\,\bar q$ on pure quaternions. Write $q = (w, \mathbf u)$. First,

$$
q\,\mathbf v = \big(-\mathbf u\cdot\mathbf v,\ w\mathbf v + \mathbf u\times\mathbf v\big).
$$

Multiplying on the right by $\bar q = (w, -\mathbf u)$, the scalar part is

$$
-w\,\mathbf u\cdot\mathbf v + (w\mathbf v + \mathbf u\times\mathbf v)\cdot\mathbf u = -w\,\mathbf u\cdot\mathbf v + w\,\mathbf v\cdot\mathbf u + 0 = 0 ,
$$

so the image is again a pure quaternion, and the vector part is

$$
\begin{aligned}
\mathbf v' &= (\mathbf u\cdot\mathbf v)\,\mathbf u + w\,(w\mathbf v + \mathbf u\times\mathbf v) - (w\mathbf v + \mathbf u\times\mathbf v)\times\mathbf u \\
&= (\mathbf u\cdot\mathbf v)\,\mathbf u + w^2\mathbf v + 2w\,\mathbf u\times\mathbf v + \mathbf u\times(\mathbf u\times\mathbf v) \\
&= (w^2 - |\mathbf u|^2)\,\mathbf v + 2(\mathbf u\cdot\mathbf v)\,\mathbf u + 2w\,\mathbf u\times\mathbf v ,
\end{aligned}
$$

using $\mathbf a\times\mathbf u = -\mathbf u\times\mathbf a$ and $\mathbf u\times(\mathbf u\times\mathbf v) = (\mathbf u\cdot\mathbf v)\mathbf u - |\mathbf u|^2\mathbf v$. Substituting $w = \cos\frac\theta2$ and $\mathbf u = \sin\frac\theta2\,\mathbf n$, and the half-angle identities $\cos^2\frac\theta2 - \sin^2\frac\theta2 = \cos\theta$, $2\sin^2\frac\theta2 = 1 - \cos\theta$, $2\sin\frac\theta2\cos\frac\theta2 = \sin\theta$:

$$
\mathbf v' = \cos\theta\,\mathbf v + (1 - \cos\theta)(\mathbf n\cdot\mathbf v)\,\mathbf n + \sin\theta\,(\mathbf n\times\mathbf v).
$$

This is Rodrigues' rotation formula: $\mathbf v \mapsto q\mathbf v q^{-1}$ is the rotation by $\theta$ about $\mathbf n$, counter-clockwise by the right-hand rule. Since $|q\mathbf v\bar q| = |q||\mathbf v||\bar q| = |\mathbf v|$, the map is an isometry, as a rotation must be.

Three consequences shape the API:

- **Composition is multiplication.** $p\,(q\mathbf v q^{-1})\,p^{-1} = (pq)\,\mathbf v\,(pq)^{-1}$, so the rotation "first $q$, then $p$" is `p * q`.
- **Double cover.** $(-q)\,\mathbf v\,(-q)^{-1} = q\mathbf v q^{-1}$, so $q$ and $-q$ are the same rotation. Indeed the angle $\theta + 2\pi$ gives $-q$. Every rotation has exactly two unit quaternions, which is why `==` does not compare rotations and why `slerp` flips the sign of one input.
- **Cheap evaluation.** `Quaternion::rotate` evaluates $\mathbf t = 2\,\mathbf u\times\mathbf v$ and $\mathbf v' = \mathbf v + w\,\mathbf t + \mathbf u\times\mathbf t$. Expanding, $\mathbf u\times\mathbf t = 2(\mathbf u\cdot\mathbf v)\mathbf u - 2|\mathbf u|^2\mathbf v$, so
  $$
  \mathbf v + w\,\mathbf t + \mathbf u\times\mathbf t = (1 - 2|\mathbf u|^2)\,\mathbf v + 2(\mathbf u\cdot\mathbf v)\,\mathbf u + 2w\,\mathbf u\times\mathbf v ,
  $$
  which equals the formula above exactly when $1 - 2|\mathbf u|^2 = w^2 - |\mathbf u|^2$, that is when $w^2 + |\mathbf u|^2 = 1$. This is why `rotate` requires a unit quaternion: it needs no division, but it relies on the norm being 1.

  For a non-zero $q$ that is not unit, write $q = \lambda\hat q$ with $\lambda = |q|$ and $\hat q = (\hat w, \hat{\mathbf u})$ unit. Every term of the expansion except $\mathbf v$ is quadratic in the components of $q$, so
  $$
  \begin{aligned}
  \mathtt{rotate}(q, \mathbf v) &= \mathbf v + \lambda^2\big(-2|\hat{\mathbf u}|^2\mathbf v + 2(\hat{\mathbf u}\cdot\mathbf v)\,\hat{\mathbf u} + 2\hat w\,\hat{\mathbf u}\times\mathbf v\big) \\
  &= \mathbf v + \lambda^2\big(R(\hat q)\,\mathbf v - \mathbf v\big),
  \end{aligned}
  $$
  where $R(\hat q)\,\mathbf v$ is the correct rotation. The result is not the rotated vector scaled: components along the axis are unchanged, and the rest is moved $\lambda^2$ times as far as it should be. With $\lambda = 1 + \delta$ the error is $(2\delta + \delta^2)\,|R(\hat q)\mathbf v - \mathbf v| \le 2(2\delta + \delta^2)\,|\mathbf v|$.

The same formula, applied to the basis vectors, gives the rotation matrix of a unit quaternion:

$$
R(q) = \begin{pmatrix}
1 - 2(y^2 + z^2) & 2(xy - wz) & 2(xz + wy) \\
2(xy + wz) & 1 - 2(x^2 + z^2) & 2(yz - wx) \\
2(xz - wy) & 2(yz + wx) & 1 - 2(x^2 + y^2)
\end{pmatrix}.
$$

The package does not return this matrix, but the Euler-angle extraction below reads its entries.

### Euler angles

Write $q_X(\alpha)$, $q_Y(\alpha)$, $q_Z(\alpha)$ for the rotations by $\alpha$ about the coordinate axes, and $R_X, R_Y, R_Z$ for their matrices. A sequence of three rotations about axes $A, B, C$ with angles $a, b, c$ can be read in two ways:

- **extrinsic** (`external=true`): about the fixed axes, first $A$, then $B$, then $C$. Later rotations multiply on the left: $q = q_C(c)\,q_B(b)\,q_A(a)$.
- **intrinsic** (`external=false`): about the axes of the moving body, first $A$, then the moved $B$, then the twice-moved $C$: $q = q_A(a)\,q_B(b)\,q_C(c)$.

The same product read in both ways shows that intrinsic $ABC$ with angles $(a, b, c)$ is extrinsic $CBA$ with angles $(c, b, a)$. The implementation uses exactly this: every `to_euler_internal_*` function calls the extrinsic function of the reversed order and reverses the triple.

**Extraction, extrinsic XYZ.** For $R = R_Z(c)\,R_Y(b)\,R_X(a)$, multiplying out the elementary matrices gives

$$
R = \begin{pmatrix}
\cos b\cos c & \cdots & \cdots \\
\cos b\sin c & \cdots & \cdots \\
-\sin b & \cos b\sin a & \cos b\cos a
\end{pmatrix}.
$$

Comparing with $R(q)$ entry by entry:

$$
\begin{aligned}
\sin b &= -R_{31} = 2(wy - xz), \\
a &= \operatorname{atan2}(R_{32}, R_{33}) = \operatorname{atan2}\big(2(wx + yz),\ 1 - 2(x^2 + y^2)\big), \\
c &= \operatorname{atan2}(R_{21}, R_{11}) = \operatorname{atan2}\big(2(wz + xy),\ 1 - 2(y^2 + z^2)\big),
\end{aligned}
$$

valid while $\cos b > 0$ (dividing both atan2 arguments by $\cos b$ does not change the angle). These are the expressions in `to_euler_external_XYZ`, with $b = \arcsin(\cdot) \in [-\pi/2, \pi/2]$. The functions `to_euler_external_YZX` and `to_euler_external_ZYX` are the same derivation with the axes permuted; a permutation that is not cyclic flips the sign inside the arcsine and the atan2 numerators. The module normalizes `q` before extracting, so the identities $w^2 + x^2 + y^2 + z^2 = 1$ used in the diagonal of $R(q)$ hold up to rounding.

**Gimbal lock.** When $\cos b = 0$, the entries $R_{32}, R_{33}, R_{21}, R_{11}$ all vanish and the first and third rotations act about the same physical axis. For $b = \pi/2$ in the XYZ case,

$$
R_Z(c)\,R_Y(\tfrac\pi2)\,R_X(a) = R_Y(\tfrac\pi2)\,R_X(a - c),
$$

so only $a - c$ is determined (and $a + c$ for $b = -\pi/2$). A conventional fix sets $c = 0$ and recovers $a$ from the entries that remain, here $a = \operatorname{atan2}(R_{12}, R_{22})$. The implementation switches to a special branch when $|\sin b| \ge 0.9998$ (about $88.85^\circ$): it prints a warning, sets $b = \pm\pi/2$ and $c = 0$, but takes the first angle from $\operatorname{atan2}(R_{13}, R_{22})$ for XYZ, and from the regular-branch formula (whose arguments are near zero) for the other orders. Neither isolates $a \mp c$, so the branch currently returns angles that do not reproduce the input; see [known deviations](#known-deviations).

**Construction.** `from_euler(roll, pitch, yaw)` with the default `"XYZ"` multiplies out $q_X(\text{roll})\,q_Y(\text{pitch})\,q_Z(\text{yaw})$ in closed form. With $c_r = \cos\frac{\text{roll}}{2}$, $s_r = \sin\frac{\text{roll}}{2}$ and so on, two applications of the Hamilton product give

$$
q_X q_Y q_Z = \big(c_r c_p c_y - s_r s_p s_y,\ \ s_r c_p c_y + c_r s_p s_y,\ \ c_r s_p c_y - s_r c_p s_y,\ \ c_r c_p s_y + s_r s_p c_y\big),
$$

the expression in the source. `to_euler_internal_XYZ` inverts it.

### Spherical linear interpolation

Unit quaternions form the 3-sphere $S^3 \subset \mathbb R^4$, and the shortest path between two orientations is a great-circle arc. Let $q_1, q_2$ be unit with $\cos\Omega = q_1\cdot q_2$, $0 < \Omega < \pi$. The unit vector

$$
q_\perp = \frac{q_2 - \cos\Omega\, q_1}{\sin\Omega}
$$

is orthogonal to $q_1$, and the arc is $\gamma(\varphi) = \cos\varphi\, q_1 + \sin\varphi\, q_\perp$. At $\varphi = t\Omega$,

$$
\begin{aligned}
\gamma(t\Omega) &= \frac{\sin\Omega\cos t\Omega - \cos\Omega\sin t\Omega}{\sin\Omega}\,q_1 + \frac{\sin t\Omega}{\sin\Omega}\,q_2 \\
&= \frac{\sin\big((1-t)\Omega\big)}{\sin\Omega}\,q_1 + \frac{\sin(t\Omega)}{\sin\Omega}\,q_2 ,
\end{aligned}
$$

which is the formula `slerp` evaluates. It moves at constant angular speed, and the rotation angle grows linearly in $t$. Because of the double cover, `slerp` first replaces $q_2$ by $-q_2$ when $q_1\cdot q_2 < 0$, so that $\Omega \le \pi/2$ and the rotation takes the short way around. It clamps $\cos\Omega$ to $[-1, 1]$ before `acos`, since rounding can push the dot product of two unit quaternions slightly past 1.

### Powers

`pow_by_int` uses $q^{2m} = (q^m)^2$ and $q^{2m+1} = q\,(q^m)^2$, which needs only associativity; all factors are powers of the same $q$, so they commute with each other. Negative exponents use $q^{-n} = (q^{-1})^n$.

`pow_by_T` uses the polar form. Every non-zero $q$ is $q = |q|\,(\cos\varphi + \hat{\mathbf n}\sin\varphi)$ with $\varphi \in [0, \pi]$ and a unit vector $\hat{\mathbf n}$, and the span of $1$ and $\hat{\mathbf n}$ is a copy of $\mathbb C$ (because $\hat{\mathbf n}^2 = -1$). De Moivre's formula then defines

$$
q^t = |q|^t\,\big(\cos t\varphi + \hat{\mathbf n}\sin t\varphi\big).
$$

The implementation computes $\varphi = \arcsin\lvert\mathbf u\rvert/|q|$, which is correct only for $\varphi \le \pi/2$, that is for a non-negative scalar part; see [known deviations](#known-deviations).

## Design decisions

### Generic components with per-function bounds

**Problem.** Quaternions are useful over exact integers (number theory, testing identities) and over `Double` (geometry), and the luna-generic ecosystem wants one type that fits both.

**Options.** A `Double`-only type; a type parameterized by a single "real number" trait; or a type with no bound on `T` whose functions each require only what they use.

**Choice.** The last. `Quaternion[T]` has no bound; `+` needs `Add`, `*` needs `Mul + Sub + Add`, `square_len` needs `Mul + Add`, and only functions with square roots or trigonometry ask for `DoubleConvert`. This follows the Luna-Flow principle that code depends on the smallest trait composition that states its needs, and it lets `Quaternion[Int]` check algebraic identities exactly.

### Scalar–vector storage

The type stores `r : T` and `vec : (T, T, T)` rather than four separate fields. The scalar–vector form is how the product, the conjugate, the inverse and the rotation are derived above, so the code reads like the derivations (`dot`, `cross`, `scale` on `vec`). The type is abstract, which keeps the representation free to change; the cost is that there are no component accessors yet.

### Why `Ring` and not `Field`

luna-generic's `Field` is `Ring + Inverse + Div`, and generic code written against it is entitled to the laws of a commutative field, such as $a b = b a$ or $a / b \cdot c = a c / b$. Quaternions satisfy every ring law and have inverses, but not commutativity, so claiming `Field` would let such code compute wrong answers silently. The package therefore implements `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring` and `Ring` (all lawful for $\mathbb H$ over a commutative `T`), plus the operation traits `Inverse` and `Conjugate`, and stops there. Division is still available through `Div` and `left_div`, but generic code has to ask for it explicitly.

### `/` is right division

**Problem.** With non-commuting multiplication, `q / r` must pick a side. Before 0.2.0 it computed $r^{-1} q$.

**Choice.** Since 0.2.0, `q / r` is $q\,r^{-1}$, the solution of $x r = q$. This is the usual convention for a division ring and keeps `Div` consistent with `Inverse` in the way it is for the luna-generic scalar types: `a / b == a * b.inv()`. It also reads naturally for rotations: `to / from` is the rotation that, applied after `from`, gives `to`. The other quotient stays available as `left_div`, with a name that says which side the inverse is on. The change is breaking and is recorded in the changelog.

### The `Double` bridge

Square roots and trigonometric functions exist for `Double` only, and the package depends on nothing but luna-generic, which has no analytic traits. `DoubleConvert` is a two-method trait that converts a component to `Double` and back, so `magnitude`, `normalize`, `slerp`, `pow_by_T` and the Euler conversions stay generic in signature while computing in `Double`. It is implemented for `Double` (as the identity) and `Int` (truncating `from_double`). The trait is declared `pub` rather than `pub(open)`, so other packages cannot implement it for their own types.

### Exact structural equality

`Eq` and `Hash` are derived and compare components exactly. Equality "as rotations" ($q \sim -q$) or "within a tolerance" depends on the application, so it is left to the caller (the tutorial shows one way). Exact equality also keeps `Eq` consistent with `Hash`.

### Explicit method promotion

MoonBit 0.10 no longer turns trait implementations into methods implicitly. [`src/extends.mbt`](../../../src/extends.mbt) promotes the operators, `equal`, `hash`, `to_string`, `conjugate`, `zero`, `one` and `inv`, which are natural operations on a quaternion. The method forms `not_equal`, `hash_combine`, `output`, `default` and `to_repr` are kept, deprecated and hidden, for compatibility.

## Correctness and invariants

### Algebraic laws

Over a commutative ring `T` with exact arithmetic (`Int`, `BigInt`), the implementation satisfies:

- the ring laws: $(\mathbb H, +, 0)$ is an abelian group, $(\mathbb H, \cdot, 1)$ a monoid, and $\cdot$ distributes over $+$ on both sides;
- $\overline{pq} = \bar q\,\bar p$, $\bar{\bar q} = q$, $q\bar q = \bar q q = |q|^2$ and $|pq|^2 = |p|^2|q|^2$;
- for exact division (a field `T` such as rationals): $q\,q^{-1} = q^{-1}q = 1$, $(q / r)\,r = q$ and $r\,(q.\mathrm{left\_div}(r)) = q$.

The package tests check the ring laws on integer samples, non-commutativity, and the two division identities.

### Floating-point error

Over `Double` the laws hold up to rounding. Each component of $pq$ is a sum of four products of a component of $p$ with a component of $q$, evaluated with four roundings of products and three of additions. The standard bound for such an inner product[^higham] gives, componentwise,

$$
\lvert \mathrm{fl}(pq)_m - (pq)_m \rvert \le \gamma_4 \sum_{l=1}^{4} \lvert p_l\rvert\,\lvert q_{\sigma_m(l)}\rvert \le \gamma_4\, |p|\,|q|, \qquad \gamma_n = \frac{n u}{1 - n u},
$$

where $\sigma_m$ is the permutation of $q$'s components that appears in component $m$ and the second inequality is Cauchy–Schwarz. Summing over the four components, $\lVert\mathrm{fl}(pq) - pq\rVert \le 2\gamma_4 |p||q|$, so by the multiplicativity of the norm

$$
(1 - 2\gamma_4)\,|p|\,|q| \le |\mathrm{fl}(pq)| \le (1 + 2\gamma_4)\,|p|\,|q| .
$$

[^higham]: N. J. Higham, *Accuracy and Stability of Numerical Algorithms*, 2nd ed., SIAM 2002, §3.1: $\lvert\mathrm{fl}(x^{\mathsf T}y) - x^{\mathsf T}y\rvert \le \gamma_n \lvert x\rvert^{\mathsf T}\lvert y\rvert$ for any order of summation.

A product of $n$ unit quaternions therefore has norm $1 + \delta$ with $|\delta| \lesssim 8nu$ to first order, where $u = 2^{-53} \approx 1.1 \times 10^{-16}$; in practice the errors partly cancel and the drift is smaller. Because `rotate` assumes $|q| = 1$, a drifted quaternion moves each vector by up to about $4\delta\,|\mathbf v|$ away from its correct image (see [unit quaternions and rotations](#unit-quaternions-and-rotations)). Long chains should call `normalize` periodically; its result has norm $1$ within a few units of $u$ (for example $1 + 2i + 3j + 4k$ normalizes to a quaternion of computed norm $0.9999999999999999$).

### Division by zero and degenerate inputs

The package does not check its inputs; degenerate cases follow the arithmetic of `T`:

| Input | `Double` | `Int` |
| --- | --- | --- |
| `inv`, `/`, `left_div` with a zero divisor | NaN components | runtime trap (integer division by zero) |
| `normalize` of zero | zero returned unchanged | zero returned unchanged |
| `pow_by_T` of zero | zero returned unchanged | zero returned unchanged |
| `from_axis_angle` with a zero axis | NaN vector part | runtime trap |
| `slerp` of a zero input | the zero input is used unnormalized | not meaningful |

Over `Int`, `inv` is zero unless $|q|^2 = 1$, and every function that goes through `DoubleConvert` truncates.

### Thresholds

`slerp` falls back to normalized linear interpolation when $\cos\Omega > 0.9995$, that is $\Omega < 0.0316$ rad. There $\sin\Omega < 0.032$, and dividing by it would amplify rounding errors in the weights. The normalized linear path stays on the same great circle, so its only error is the angle it reaches. The point $(1 - t)\,q_1 + t\,q_2$ has, in the basis $q_1, q_\perp$ of the arc, the coordinates $(1 - t + t\cos\Omega,\ t\sin\Omega)$, so it sits at the angle

$$
\varphi(t) = \operatorname{atan2}\big(t\sin\Omega,\ 1 - t + t\cos\Omega\big)
$$

instead of $t\Omega$. Expanding $\sin\Omega = \Omega - \Omega^3/6$, $\cos\Omega = 1 - \Omega^2/2$ and $\arctan x = x - x^3/3$ to third order,

$$
\begin{aligned}
\frac{t\sin\Omega}{1 - t + t\cos\Omega} &= t\Omega - \frac{t\Omega^3}{6} + \frac{t^2\Omega^3}{2} + O(\Omega^5), \\
\varphi(t) - t\Omega &= \Omega^3\Big(-\frac{t}{6} + \frac{t^2}{2} - \frac{t^3}{3}\Big) + O(\Omega^5) = -\frac{\Omega^3}{6}\,t(1 - t)(1 - 2t) + O(\Omega^5).
\end{aligned}
$$

The cubic $t(1-t)(1-2t)$ has its largest absolute value $\sqrt 3/18$ on $[0, 1]$ at $t = (3 \mp \sqrt 3)/6$, so the error is at most $\Omega^3\sqrt 3/108 \approx 5.07 \times 10^{-7}$ rad on $S^3$ at the threshold (about $10^{-6}$ rad of rotation angle, because rotation angles are twice the angles on $S^3$), and smaller below it.

The Euler conversions treat $|\sin b| \ge 0.9998$ as gimbal lock. Rounding $b$ to $\pm\pi/2$ there costs up to $\pi/2 - \arcsin 0.9998 \approx 0.020$ rad in the middle angle.

### Complexity

Every operation is $O(1)$ on four components: a Hamilton product costs 16 multiplications and 12 additions or subtractions, `rotate` 18 multiplications and 12 additions or subtractions (plus one addition to form the constant 2). `pow_by_int(n)` uses $O(\log |n|)$ products and recursion depth.

### Known deviations

These are deviations of the current implementation from the mathematics above. They are documented here rather than hidden, and are reported for fixing:

- `from_euler` with `"ZYX"` or `"YZX"` does not evaluate a product of axis rotations; the results are not unit quaternions. `"ZXY"` takes its angles by position while `"YXZ"` takes them by axis.
- `to_euler_external_XZY` (and therefore `to_euler_internal_YZX`) evaluates the intrinsic X-Y-Z extraction instead of the named sequence.
- The gimbal-lock branch of the Euler extraction does not isolate the free angle (see above), and it reports the warning with `println`. For extrinsic XYZ it reads $\operatorname{atan2}(R_{13}, R_{22})$; at exact lock both entries equal $\cos(a \mp c)$, so the first angle is always $\pm\pi/4$ or $\pm3\pi/4$. For $0.9998 \le |\sin b| < 1$ the third angle is still determined but is set to $0$.
- `pow_by_T` computes $\varphi$ with `asin`, which cannot exceed $\pi/2$; $\operatorname{atan2}(\lvert\mathbf u\rvert, w)$ would cover $[0, \pi]$. The argument of `asin` is $|\mathbf u|/|q|$ computed after `normalize`; for a pure quaternion it can round to $1 + 2^{-52}$, where `asin` returns NaN. `atan2` would also remove this failure.
- `pow_by_int` negates a negative exponent; for the smallest `Int` the negation overflows to the same value and the call never returns.
- The `Ring` instance is declared for every `T : Ring`, but the Hamilton product is associative only when `T` is commutative, so `Quaternion[Quaternion[T]]` is a `Ring` instance that breaks associativity (the [API](../api/core.md#trait-implementations) shows a counterexample).

## Alternatives rejected

- **Implementing `Field`.** Rejected because generic `Field` code may rely on commutativity (see above).
- **Keeping `/` as left division.** It contradicted `a / b == a * b.inv()` and the usual reading of `to / from` for rotations.
- **A `Double`-only type.** It would lose exact arithmetic over `Int` and the luna-generic ring structure for other scalar types.
- **Storing four named fields or a rotation matrix.** Four fields hide the scalar–vector structure the formulas use; a matrix has nine entries, needs re-orthogonalization instead of a cheap normalization, and cannot be interpolated as simply.
- **Comparing with a tolerance in `Eq`.** A tolerance-based `==` is not transitive and cannot agree with `Hash`.

## Boundaries

The package deliberately does not:

- provide rotation matrices, exponential and logarithm maps, or quaternion calculus (dual quaternions, derivatives of orientations);
- check its inputs or return `Result`: degenerate inputs follow the arithmetic of `T`, and `rotate` trusts that its receiver is a unit quaternion;
- implement luna-generic `Field` or `Num`, or make quaternions an ordered type;
- depend on `arithmetic`, `linear-algebra` or `luna-complex`; its only Luna-Flow dependency is luna-generic;
- choose a tolerance for comparing rotations; that is left to the caller.
