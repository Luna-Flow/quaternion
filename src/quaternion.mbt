/// Quaternion struct with real component `r` and vector components `vec`
struct Quaternion[T] {
  r : T
  vec : (T, T, T)
} derive(Eq, Hash)

///|
/// Computes the cross product of two 3D vectors.
fn cross[T : Mul + Sub](a : (T, T, T), b : (T, T, T)) -> (T, T, T) {
  (a.1 * b.2 - a.2 * b.1, a.2 * b.0 - a.0 * b.2, a.0 * b.1 - a.1 * b.0)
}

///|
/// Adds two 3D vectors component-wise.
fn add[T : Add](a : (T, T, T), b : (T, T, T)) -> (T, T, T) {
  (a.0 + b.0, a.1 + b.1, a.2 + b.2)
}

///|
/// Scales a 3D vector by a scalar value.
fn scale[T : Mul](a : (T, T, T), s : T) -> (T, T, T) {
  (a.0 * s, a.1 * s, a.2 * s)
}

///|
/// Computes the dot product of two 3D vectors.
fn dot[T : Mul + Add](a : (T, T, T), b : (T, T, T)) -> T {
  a.0 * b.0 + a.1 * b.1 + a.2 * b.2
}

///|
/// Applies a function to each component of a 3D vector.
fn map[T, U](a : (T, T, T), f : (T) -> U) -> (U, U, U) {
  (f(a.0), f(a.1), f(a.2))
}

///|
/// Returns the identity quaternion (1 + 0i + 0j + 0k).
pub fn id[T : @lg.Num]() -> Quaternion[T] {
  { r: T::one(), vec: (T::zero(), T::zero(), T::zero()) }
}

///|
/// Default implementation returns the identity quaternion.
pub impl[T : @lg.Num] Default for Quaternion[T] with default() {
  id()
}

///|
/// Returns a string representation of the quaternion in the form "a + bi + cj + dk".
pub impl[T : Show] Show for Quaternion[T] with to_string(self) {
  "\{self.r} + \{self.vec.0}i + \{self.vec.1}j + \{self.vec.2}k"
}

///|
/// Outputs the quaternion to a logger.
pub impl[T : Show] Show for Quaternion[T] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Adds two quaternions component-wise.
pub impl[T : Add] Add for Quaternion[T] with op_add(self, other) {
  {
    r: self.r + other.r,
    vec: (
      self.vec.0 + other.vec.0,
      self.vec.1 + other.vec.1,
      self.vec.2 + other.vec.2,
    ),
  }
}

///|
/// Scales the quaternion by a scalar value.
pub fn Quaternion::scale[T : Mul](self : Quaternion[T], s : T) -> Quaternion[T] {
  { r: self.r * s, vec: (self.vec.0 * s, self.vec.1 * s, self.vec.2 * s) }
}

///|
/// Computes the multiplicative inverse of the quaternion.
pub impl[T : Div + @lg.Num] @lg.Inverse for Quaternion[T] with inv(self) {
  let inv = T::one() / square_len(self)
  self.conjugate() |> Quaternion::scale(inv)
}

///|
/// Computes the dot product of two quaternions.
pub fn Quaternion::dot[T : Mul + Add](
  self : Quaternion[T],
  other : Quaternion[T]
) -> T {
  self.r * other.r +
  self.vec.0 * other.vec.0 +
  self.vec.1 * other.vec.1 +
  self.vec.2 * other.vec.2
}

///|
/// Multiplies two quaternions using Hamilton product.
pub impl[T : Mul + Sub + Add] Mul for Quaternion[T] with op_mul(self, other) {
  {
    r: self.r * other.r - dot(self.vec, other.vec),
    vec: cross(self.vec, other.vec)
    |> add(add(scale(other.vec, self.r), scale(self.vec, other.r))),
  }
}

///|
/// Divides two quaternions.
pub impl[T : Add + Mul + Div + Sub] Div for Quaternion[T] with op_div(q, r) {
  let d = r.square_len()
  {
    r: (q.r * r.r + dot(q.vec, r.vec)) / d,
    vec: (
      (q.vec.0 * r.r - r.vec.0 * q.r - r.vec.1 * q.vec.2 + r.vec.2 * q.vec.1) /
      d,
      (q.vec.1 * r.r + r.vec.0 * q.vec.2 - r.vec.1 * q.r - r.vec.2 * q.vec.0) /
      d,
      (q.vec.2 * r.r - r.vec.0 * q.vec.1 + r.vec.1 * q.vec.0 - r.vec.2 * q.r) /
      d,
    ),
  }
}

///|
/// Negates the quaternion.
pub impl[T : Neg] Neg for Quaternion[T] with op_neg(self) {
  { r: -self.r, vec: map(self.vec, Neg::op_neg) }
}

///|
/// Subtracts two quaternions.
pub impl[T : Neg + Add] Sub for Quaternion[T] with op_sub(self, other) {
  self + -other
}

///|
test "basic arithmetic" {
  let q1 = Quaternion::from_vec((1, 2, 3, 4))
  let q2 = Quaternion::from_vec((5, 6, 7, 8))
  inspect!(q1 + q2, content="6 + 8i + 10j + 12k")
  inspect!(q1 - q2, content="-4 + -4i + -4j + -4k")
  inspect!(q1 * q2, content="-60 + 12i + 30j + 24k")
  inspect!(q2 * q1, content="-60 + 20i + 14j + 32k")
  inspect!(
    q1.map(Int::to_double) / q2.map(Int::to_double),
    content="0.40229885057471265 + 0i + 0.09195402298850575j + 0.04597701149425287k",
  )
}

///|
/// Applies a function to each component of the quaternion.
pub fn Quaternion::map[T, U](
  self : Quaternion[T],
  f : (T) -> U
) -> Quaternion[U] {
  { r: f(self.r), vec: map(self.vec, f) }
}

///|
/// Computes the conjugate of the quaternion (negates vector components).
pub impl[T : Neg] @lg.Conjugate for Quaternion[T] with conjugate(self) {
  { r: self.r, vec: map(self.vec, Neg::op_neg) }
}

///|
/// Computes the squared length (norm) of the quaternion.
pub fn square_len[T : Mul + Add](self : Quaternion[T]) -> T {
  self.r * self.r + dot(self.vec, self.vec)
}

///|
/// Computes the magnitude (norm) of the quaternion.
pub fn magnitude[T : @lg.Num + DoubleConvert](self : Quaternion[T]) -> T {
  square_len(self).to_double().sqrt() |> T::from_double()
}

///|
/// Rotates a 3D vector using this unit quaternion.
pub fn rotate[T : @lg.Num + Sub](
  self : Quaternion[T],
  v : (T, T, T)
) -> (T, T, T) {
  let _2 = T::one() + T::one()
  let t : (T, T, T) = scale(cross(self.vec, v), _2)
  v |> add(scale(t, self.r)) |> add(cross(self.vec, t))
}

///|
/// Normalizes the quaternion to unit length.
pub fn normalize[T : @lg.Num + DoubleConvert + Div](
  self : Quaternion[T]
) -> Quaternion[T] {
  self.scale(T::one() / self.magnitude())
}

///|
/// Creates a quaternion from a 4-component vector (scalar, i, j, k).
pub fn Quaternion::from_vec[T : @lg.Num](v : (T, T, T, T)) -> Quaternion[T] {
  { r: v.0, vec: (v.1, v.2, v.3) }
}

/// Test cases demonstrating other quaternion operations
test "others" {
  let q : Quaternion[Double] = Quaternion::from_vec((1, 2, 3, 4))
  inspect!(q.square_len(), content="30")
  inspect!(q.magnitude(), content="5.477225575051661")
  inspect!(q.conjugate(), content="1 + -2i + -3j + -4k")
  inspect!(q.inv(), content="0.03333333333333333 + -0.06666666666666667i + -0.1j + -0.13333333333333333k")
}
