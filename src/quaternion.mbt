///| Quaternion struct with real component `r` and vector components `vec`
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
  if self.magnitude().to_double() == 0.0 {
    self
  } else {
    self.scale(T::one() / self.magnitude())
  }
}

///|
/// Creates a quaternion from a 4-component vector (scalar, i, j, k).
pub fn Quaternion::from_vec[T : @lg.Num](v : (T, T, T, T)) -> Quaternion[T] {
  { r: v.0, vec: (v.1, v.2, v.3) }
}

///| Test cases demonstrating other quaternion operations
test "others" {
  let q : Quaternion[Double] = Quaternion::from_vec((1, 2, 3, 4))
  inspect!(q.square_len(), content="30")
  inspect!(q.magnitude(), content="5.477225575051661")
  inspect!(q.conjugate(), content="1 + -2i + -3j + -4k")
  inspect!(
    q.inv(),
    content="0.03333333333333333 + -0.06666666666666667i + -0.1j + -0.13333333333333333k",
  )
  inspect!(
    q.normalize(),
    content="0.18257418583505536 + 0.3651483716701107i + 0.5477225575051661j + 0.7302967433402214k",
  )
}

///|
/// Creates a quaternion from an axis and angle.
pub fn from_axis_angle[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div](
  axis : (T, T, T),
  angle : T
) -> Quaternion[T] {
  let half_angle = angle / T::from_double(2.0)
  let sin_half = half_angle.to_double().sin() |> T::from_double()
  let cos_half = half_angle.to_double().cos() |> T::from_double()
  let axis_len = dot(axis, axis).to_double().sqrt() |> T::from_double()
  let axis = (axis.0 / axis_len, axis.1 / axis_len, axis.2 / axis_len)
  {
    r: cos_half,
    vec: (axis.0 * sin_half, axis.1 * sin_half, axis.2 * sin_half),
  }
}

///|
test "from_axis_angle" {
  let axis = (1.0, 1.0, 1.0)
  let angle = @math.PI / 4.0
  let res = from_axis_angle(axis, angle)
  inspect!(
    res,
    content="0.9238795325112867 + 0.22094238269039457i + 0.22094238269039457j + 0.22094238269039457k",
  )
}

///|
/// Performs spherical linear interpolation between two quaternions.
pub fn slerp[T : DoubleConvert + @lg.Num + Mul + Add + Sub + Div](
  q1 : Quaternion[T],
  q2 : Quaternion[T],
  t : Double
) -> Quaternion[T] {
  let q1_standard = q1.normalize()
  let q2_standard = q2.normalize()
  let dot_raw = q1_standard.dot(q2_standard).to_double()
  let q2_corrected = if dot_raw < 0.0 { -q2_standard } else { q2_standard }

  // constraint dot in [-1, 1], avoid acos out of bound error
  let d = q1_standard.dot(q2_corrected).to_double()
  let dot_clamped = if d > 1.0 { 1.0 } else if d < -1.0 { -1.0 } else { d }
  if dot_clamped > 0.9995 {
    (q1_standard + (q2_corrected - q1_standard).scale(T::from_double(t))).normalize()
  } else {
    let theta = dot_clamped.acos()
    let sin_theta = theta.sin()
    let weight1 = T::from_double(((1.0 - t) * theta).sin() / sin_theta)
    let weight2 = T::from_double((t * theta).sin() / sin_theta)
    q1_standard.scale(weight1) + q2_corrected.scale(weight2)
  }
}

///|
test "slerp" {
  let q1 = Quaternion::{ r: 0.7071, vec: (0.7071, 0, 0) }
  let q2 = Quaternion::{ r: 0.7071, vec: (0, 0.7071, 0) }
  inspect!(
    slerp(q1, q2, 0.5),
    content="0.816496580927726 + 0.408248290463863i + 0.408248290463863j + 0k",
  )
  let q1 = Quaternion::{ r: 1.0, vec: (1, 1, 1) }
  let q2 = Quaternion::{ r: -1.0, vec: (1, 2, 3) }
  inspect!(
    slerp(q1, q2, 0.5),
    content="0.13328912463299897 + 0.41794541888760534i + 0.5602735660149085j + 0.7026017131422118k",
  )
}

///| 
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in ZYX-Order Order
pub fn to_euler[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div](
  self : Quaternion[T]
) -> (T, T, T) {
  let sinr_cosp = 2.0 *
    (self.r * self.vec.0 + self.vec.1 * self.vec.2).to_double()
  let cosr_cosp = 1.0 -
    2.0 * (self.vec.0 * self.vec.0 + self.vec.1 * self.vec.1).to_double()
  let roll = sinr_cosp.to_double().atan2(cosr_cosp.to_double())
    |> T::from_double()
  let sinp = 2.0 * (self.r * self.vec.1 - self.vec.2 * self.vec.0).to_double()
  let pitch = if sinp.abs() >= 1.0 {
    sinp.to_double().asin().to_double() |> T::from_double()
  } else {
    sinp.to_double().asin().to_double() |> T::from_double()
  }
  let siny_cosp = 2.0 *
    (self.r * self.vec.2 + self.vec.0 * self.vec.1).to_double()
  let cosy_cosp = 1.0 -
    2.0 * (self.vec.1 * self.vec.1 + self.vec.2 * self.vec.2).to_double()
  let yaw = siny_cosp.to_double().atan2(cosy_cosp.to_double())
    |> T::from_double()
  (roll, pitch, yaw)
}

///|
test "to_euler" {
  let q1 = Quaternion::{ r: 0.5, vec: (0.5, 0.5, 0.5) }
  let q2 = Quaternion::{ r: 1.0, vec: (0.0, 0.0, 0.0) }
  let q3 = Quaternion::{ r: 0.258, vec: (0.258, 0.516, 0.775) }
  inspect!(q1.to_euler(), content="(1.5707963267948966, 0, 1.5707963267948966)")
  inspect!(q2.to_euler(), content="(0, 0, 0)")
  inspect!(
    q3.to_euler(),
    content="(1.2266592237621043, -0.13404506154708215, 2.4044498284179303)",
  )
}

///| 
/// Converts the Euler angles to the quaternion (x, ai, bj, ck) In XYZ-Order Order  
pub fn from_euler[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div](
  roll : T,
  pitch : T,
  yaw : T
) -> Quaternion[T] {
  let half_roll = roll.to_double() * 0.5
  let half_pitch = pitch.to_double() * 0.5
  let half_yaw = yaw.to_double() * 0.5
  let cr = half_roll.cos() |> T::from_double()
  let sr = half_roll.sin() |> T::from_double()
  let cp = half_pitch.cos() |> T::from_double()
  let sp = half_pitch.sin() |> T::from_double()
  let cy = half_yaw.cos() |> T::from_double()
  let sy = half_yaw.sin() |> T::from_double()
  Quaternion::{
    r: cr * cp * cy - sr * sp * sy,
    vec: (
      sr * cp * cy + cr * sp * sy,
      cr * sp * cy - sr * cp * sy,
      cr * cp * sy + sr * sp * cy,
    ),
  }
}

///|
test "from_euler" {
  inspect!(
    from_euler(1.0, 1.0, 1.0),
    content="0.5656758145325667 + 0.5709414713577319i + 0.16751879124639693j + 0.5709414713577319k",
  )
  inspect!(
    from_euler(0.0, 0.0, 1.0),
    content="0.8775825618903728 + 0i + 0j + 0.479425538604203k",
  )
}

///|
/// If the exponent isn't of type Int, please use the pow_by_T function to calculate.
/// Computes the power of a quaternion. Like q^2
pub fn Quaternion::pow_by_int[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq](
  self : Quaternion[T],
  exponent : Int
) -> Quaternion[T] {
  if exponent == 0 {
    Quaternion::{ r: T::one(), vec: (T::zero(), T::zero(), T::zero()) }
  } else if exponent < 0 {
    self.inv().pow_by_int(-exponent)
  } else if exponent == 1 {
    self
  } else {
    let half_pow = self.pow_by_int(exponent / 2)
    if exponent % 2 == 0 {
      half_pow * half_pow
    } else {
      self * half_pow * half_pow
    }
  }
}

///|
/// If the exponent is of type Int, please use the pow_by_int function.
/// Computes the power of a quaternion. Like q^(2.5)
pub fn Quaternion::pow_by_T[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq](
  self : Quaternion[T],
  exponent : T
) -> Quaternion[T] {
  let len = self.magnitude()
  if self.magnitude() == T::zero() {
    return self
  }
  let unit = self.normalize()
  let v_norm_sq = dot(unit.vec, unit.vec).to_double()
  let v_norm = v_norm_sq.sqrt()
  if v_norm == 0.0 {
    let new_r = self.r.to_double().pow(exponent.to_double())
    Quaternion::{
      r: T::from_double(new_r),
      vec: (T::zero(), T::zero(), T::zero()),
    }
  } else {
    let theta = 2.0 * v_norm.asin()
    let new_angle = theta * exponent.to_double()
    let half_new_angle = new_angle / 2.0
    let new_len = len.to_double().pow(exponent.to_double()) |> T::from_double()
    let sin_half = half_new_angle.sin() |> T::from_double()
    let cos_half = half_new_angle.cos() |> T::from_double()
    let axis = (
      unit.vec.0 / T::from_double(v_norm),
      unit.vec.1 / T::from_double(v_norm),
      unit.vec.2 / T::from_double(v_norm),
    )
    Quaternion::{
      r: cos_half * new_len,
      vec: (
        axis.0 * sin_half * new_len,
        axis.1 * sin_half * new_len,
        axis.2 * sin_half * new_len,
      ),
    }
  }
}

///|
test "pow" {
  let q : Quaternion[Double] = Quaternion::from_vec((2, 2, 3, 4))
  inspect!(q.pow_by_int(2), content="-25 + 8i + 12j + 16k")
  inspect!(
    q.pow_by_T(2),
    content="-25.00000000000001 + 7.999999999999995i + 11.999999999999995j + 15.99999999999999k",
  )
}

/// convert quaternion to rotation matrix
// pub fn to_rotation_matrix[T](self : Quaternion[T]) -> Matrix[T] {
//    ...
// }
