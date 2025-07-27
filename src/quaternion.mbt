///| Quaternion struct with real component `r` and vector components `vec`
struct Quaternion[T] {
  r : T
  vec : (T, T, T)
} derive(Eq, Hash)

///|
/// Computes the cross product of two 3D vectors.
fn[T : Mul + Sub] cross(a : (T, T, T), b : (T, T, T)) -> (T, T, T) {
  (a.1 * b.2 - a.2 * b.1, a.2 * b.0 - a.0 * b.2, a.0 * b.1 - a.1 * b.0)
}

///|
/// Adds two 3D vectors component-wise.
fn[T : Add] add(a : (T, T, T), b : (T, T, T)) -> (T, T, T) {
  (a.0 + b.0, a.1 + b.1, a.2 + b.2)
}

///|
/// Scales a 3D vector by a scalar value.
fn[T : Mul] scale(a : (T, T, T), s : T) -> (T, T, T) {
  (a.0 * s, a.1 * s, a.2 * s)
}

///|
/// Computes the dot product of two 3D vectors.
fn[T : Mul + Add] dot(a : (T, T, T), b : (T, T, T)) -> T {
  a.0 * b.0 + a.1 * b.1 + a.2 * b.2
}

///|
/// Applies a function to each component of a 3D vector.
fn[T, U] map(a : (T, T, T), f : (T) -> U) -> (U, U, U) {
  (f(a.0), f(a.1), f(a.2))
}

///|
/// Returns the identity quaternion (1 + 0i + 0j + 0k).
pub fn[T : @lg.Num] id() -> Quaternion[T] {
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
pub fn[T : Mul] Quaternion::scale(self : Quaternion[T], s : T) -> Quaternion[T] {
  { r: self.r * s, vec: (self.vec.0 * s, self.vec.1 * s, self.vec.2 * s) }
}

///|
/// Computes the multiplicative inverse of the quaternion.
pub impl[T : Div + @lg.Num] @lg.Inverse for Quaternion[T] with inv(self) {
  let inv = T::one() / self.square_len()
  self.conjugate() |> Quaternion::scale(inv)
}

///|
/// Computes the dot product of two quaternions.
pub fn[T : Mul + Add] Quaternion::dot(
  self : Quaternion[T],
  other : Quaternion[T],
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
  inspect(q1 + q2, content="6 + 8i + 10j + 12k")
  inspect(q1 - q2, content="-4 + -4i + -4j + -4k")
  inspect(q1 * q2, content="-60 + 12i + 30j + 24k")
  inspect(q2 * q1, content="-60 + 20i + 14j + 32k")
  inspect(
    q1.map(Int::to_double) / q2.map(Int::to_double),
    content="0.40229885057471265 + 0i + 0.09195402298850575j + 0.04597701149425287k",
  )
}

///|
/// Applies a function to each component of the quaternion.
pub fn[T, U] Quaternion::map(
  self : Quaternion[T],
  f : (T) -> U,
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
pub fn[T : Mul + Add] square_len(self : Quaternion[T]) -> T {
  self.r * self.r + dot(self.vec, self.vec)
}

///|
/// Computes the magnitude (norm) of the quaternion.
pub fn[T : @lg.Num + DoubleConvert] magnitude(self : Quaternion[T]) -> T {
  self.square_len().to_double().sqrt() |> T::from_double()
}

///|
/// Rotates a 3D vector using this unit quaternion.
pub fn[T : @lg.Num + Sub] rotate(
  self : Quaternion[T],
  v : (T, T, T),
) -> (T, T, T) {
  let _2 = T::one() + T::one()
  let t : (T, T, T) = scale(cross(self.vec, v), _2)
  v |> add(scale(t, self.r)) |> add(cross(self.vec, t))
}

///|
/// Normalizes the quaternion to unit length.
pub fn[T : @lg.Num + DoubleConvert + Div + Eq] normalize(
  self : Quaternion[T],
) -> Quaternion[T] {
  if self.magnitude() == T::zero() {
    self
  } else {
    self.scale(T::one() / self.magnitude())
  }
}

///|
/// Creates a quaternion from a 4-component vector (scalar, i, j, k).
pub fn[T] Quaternion::from_vec(v : (T, T, T, T)) -> Quaternion[T] {
  { r: v.0, vec: (v.1, v.2, v.3) }
}

///| Test cases demonstrating other quaternion operations
test "others" {
  let q : Quaternion[Double] = Quaternion::from_vec((1, 2, 3, 4))
  inspect(q.square_len(), content="30")
  inspect(q.magnitude(), content="5.477225575051661")
  inspect(q.conjugate(), content="1 + -2i + -3j + -4k")
  inspect(
    q.inv(),
    content="0.03333333333333333 + -0.06666666666666667i + -0.1j + -0.13333333333333333k",
  )
  inspect(
    q.normalize(),
    content="0.18257418583505536 + 0.3651483716701107i + 0.5477225575051661j + 0.7302967433402214k",
  )
}

///|
/// Creates a quaternion from an axis and angle.
pub fn[T : DoubleConvert + Mul + Add + Div] from_axis_angle(
  axis : (T, T, T),
  angle : T,
) -> Quaternion[T] {
  let half_angle = angle / T::from_double(2.0)
  let sin_half = @math.sin(half_angle.to_double()) |> T::from_double()
  let cos_half = @math.cos(half_angle.to_double()) |> T::from_double()
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
  inspect(
    res,
    content="0.9238795325112867 + 0.22094238269039457i + 0.22094238269039457j + 0.22094238269039457k",
  )
}

///|
/// Performs spherical linear interpolation between two quaternions.
pub fn[T : DoubleConvert + @lg.Num + Mul + Add + Div + Eq] slerp(
  q1 : Quaternion[T],
  q2 : Quaternion[T],
  t : Double,
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
    let theta = @math.acos(dot_clamped)
    let sin_theta = @math.sin(theta)
    let weight1 = T::from_double(@math.sin((1.0 - t) * theta) / sin_theta)
    let weight2 = T::from_double(@math.sin(t * theta) / sin_theta)
    q1_standard.scale(weight1) + q2_corrected.scale(weight2)
  }
}

///|
test "slerp" {
  let q1 = Quaternion::{ r: 0.7071, vec: (0.7071, 0, 0) }
  let q2 = Quaternion::{ r: 0.7071, vec: (0, 0.7071, 0) }
  inspect(
    slerp(q1, q2, 0.5),
    content="0.816496580927726 + 0.408248290463863i + 0.408248290463863j + 0k",
  )
  let q1 = Quaternion::{ r: 1.0, vec: (1, 1, 1) }
  let q2 = Quaternion::{ r: -1.0, vec: (1, 2, 3) }
  inspect(
    slerp(q1, q2, 0.5),
    content="0.13328912463299897 + 0.41794541888760534i + 0.5602735660149085j + 0.7026017131422118k",
  )
}

///| 
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in different Orders, all measured in radians.
/// 'roll' : the rotation angle around the X-axis
/// 'pitch' : the rotation angle around the Y-axis
/// 'yaw' : the rotation angle around the Z-axis
/// 'order' in {"XYZ", "XZY", "YZX", "ZYX"} 
/// 'external' is 'true', Result will be External rotation. Otherwise, Result will be Internal rotation
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler(
  self : Quaternion[T],
  order~ : String = "ZYX",
  external~ : Bool = true,
) -> (T, T, T) {
  if external {
    match order {
      "XYZ" => self.to_euler_external_XYZ()
      "XZY" => self.to_euler_external_XZY()
      "YZX" => self.to_euler_external_YZX()
      "ZYX" => self.to_euler_external_ZYX()
      _ => abort("order error. Please check input format and retry")
    }
  } else {
    match order {
      "XYZ" => self.to_euler_internal_XYZ()
      "YZX" => self.to_euler_internal_YZX()
      "ZYX" => self.to_euler_internal_ZYX()
      "XZY" => self.to_euler_internal_XZY()
      _ => abort("order error. Please check input format and retry")
    }
  }
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in external XYZ-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_external_XYZ(
  self : Quaternion[T],
) -> (T, T, T) {
  let q = self.normalize()
  let (w, x, y, z) = (q.r, q.vec.0, q.vec.1, q.vec.2)
  let sp = 2.0 * (w * y - z * x).to_double()
  // avoid Gimbal Lock
  guard sp.abs() < 0.9998 else {
    println(
      "UserWarning: Gimbal lock detected. Setting third angle to zero since it is not possible to uniquely determine all angles.",
    )
    let adjust_cy = 2.0 * (w * y + x * z).to_double()
    let adjust_cr = 1.0 - 2.0 * (x * x + z * z).to_double()
    (
      @math.atan2(adjust_cy, adjust_cr) |> T::from_double(),
      T::from_double(@math.PI / 2.0 * sp.signum()),
      T::from_double(0.0),
    )
  }
  let cy = 2.0 * (w * x + z * y).to_double()
  let cr = 1.0 - 2.0 * (x * x + y * y).to_double()
  let roll = @math.atan2(cy, cr) |> T::from_double()
  let pitch = @math.asin(sp) |> T::from_double()
  let sx = 2.0 * (w * z + x * y).to_double()
  let cx = 1.0 - 2.0 * (z * z + y * y).to_double()
  let yaw = @math.atan2(sx, cx) |> T::from_double()
  (roll, pitch, yaw)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in external YZX-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_external_YZX(
  self : Quaternion[T],
) -> (T, T, T) {
  let q = self.normalize()
  let (w, x, y, z) = (q.r, q.vec.0, q.vec.1, q.vec.2)
  let cp = 2.0 * (w * y + x * z).to_double()
  let cr = 1.0 - 2.0 * (z * z + y * y).to_double()
  let roll = @math.atan2(cp, cr) |> T::from_double()
  let sp = 2.0 * (w * z - x * y).to_double()
  // avoid Gimbal Lock
  guard sp.abs() < 0.9998 else {
    println(
      "UserWarning: Gimbal lock detected. Setting third angle to zero since it is not possible to uniquely determine all angles.",
    )
    (roll, T::from_double(@math.PI / 2.0 * sp.signum()), T::from_double(0.0))
  }
  let pitch = @math.asin(sp) |> T::from_double()
  let cy = 2.0 * (w * x + z * y).to_double()
  let cx = 1.0 - 2.0 * (z * z + x * x).to_double()
  let yaw = @math.atan2(cy, cx) |> T::from_double()
  (roll, pitch, yaw)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in external ZYX-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_external_ZYX(
  self : Quaternion[T],
) -> (T, T, T) {
  let q = self.normalize()
  let (x, y, z, w) = (q.vec.0, q.vec.1, q.vec.2, q.r)
  let sinr = 2.0 * (w * z - y * x).to_double()
  let cosr = 1.0 - 2.0 * (z * z + y * y).to_double()
  let roll = @math.atan2(sinr, cosr) |> T::from_double()
  let sp = 2.0 * (w * y + z * x).to_double()
  guard sp.abs() < 0.9998 else {
    println(
      "UserWarning: Gimbal lock detected. Setting pitch to ±90° and yaw to zero.",
    )
    (roll, T::from_double(@math.PI / 2.0 * sp.signum()), T::from_double(0.0))
  }
  let pitch = @math.asin(sp) |> T::from_double()
  let siny = 2.0 * (w * x - z * y).to_double()
  let cosy = 1.0 - 2.0 * (x * x + y * y).to_double()
  let yaw = @math.atan2(siny, cosy) |> T::from_double()
  (roll, pitch, yaw)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in external XZY-Order (active rotation)
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_external_XZY(
  self : Quaternion[T],
) -> (T, T, T) {
  let q = self.normalize()
  let (x, y, z, w) = (q.vec.0, q.vec.1, q.vec.2, q.r)
  let sinr_cosp = 2.0 * (w * x - y * z).to_double()
  let cosr_cosp = 1.0 - 2.0 * (x * x + y * y).to_double()
  let roll = @math.atan2(sinr_cosp, cosr_cosp) |> T::from_double()
  let sp = 2.0 * (w * y + x * z).to_double()
  guard sp.abs() < 0.9998 else {
    println(
      "UserWarning: Gimbal lock detected. Setting pitch to ±90° and yaw to zero.",
    )
    (roll, T::from_double(@math.PI / 2.0 * sp.signum()), T::from_double(0.0))
  }
  let pitch = @math.asin(sp) |> T::from_double()
  let siny_cosp = 2.0 * (w * z - x * y).to_double()
  let cosy_cosp = 1.0 - 2.0 * (y * y + z * z).to_double()
  let yaw = @math.atan2(siny_cosp, cosy_cosp) |> T::from_double()
  (roll, pitch, yaw)
}

///|
test "to_euler" {
  let q3 = Quaternion::{ r: 0.258, vec: (0.258, 0.516, 0.775) }
  inspect(
    q3.to_euler(order="XYZ"),
    content="(1.2266506748485178, -0.1340438478746415, 2.4044437241372796)",
  )
  inspect(
    q3.to_euler(order="XZY"),
    content="(-1.1059098961604412, 0.7290346960862234, 2.9614299881239803)",
  )
  inspect(
    q3.to_euler(order="YZX"),
    content="(2.4044437241372796, 0.1340438478746415, 1.9149419787412751)",
  )
  inspect(
    q3.to_euler(order="ZYX"),
    content="(2.9614299881239803, 0.7290346960862234, -1.1059098961604412)",
  )
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in internal XZY-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_internal_XYZ(
  self : Quaternion[T],
) -> (T, T, T) {
  let (roll, pitch, yaw) = self.to_euler_external_ZYX()
  (yaw, pitch, roll)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in internal XZY-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_internal_YZX(
  self : Quaternion[T],
) -> (T, T, T) {
  let (roll, pitch, yaw) = self.to_euler_external_XZY()
  (yaw, pitch, roll)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in internal XZY-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_internal_XZY(
  self : Quaternion[T],
) -> (T, T, T) {
  let (roll, pitch, yaw) = self.to_euler_external_YZX()
  (yaw, pitch, roll)
}

///|
/// Converts the quaternion to Euler angles (roll, pitch, yaw) in internal XZY-Order
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] to_euler_internal_ZYX(
  self : Quaternion[T],
) -> (T, T, T) {
  let (roll, pitch, yaw) = self.to_euler_external_XYZ()
  (yaw, pitch, roll)
}

///| 
/// Converts the Euler angles to the quaternion (x, ai, bj, ck) In different Orders 
/// 'order' in {"XYZ", "YXZ", "ZYX", "YZX", "ZXY"} 
pub fn[T : DoubleConvert + Mul + Add + Sub] from_euler(
  roll : T,
  pitch : T,
  yaw : T,
  order~ : String = "XYZ",
) -> Quaternion[T] {
  let half_roll = roll.to_double() * 0.5
  let half_pitch = pitch.to_double() * 0.5
  let half_yaw = yaw.to_double() * 0.5
  let cr = @math.cos(half_roll) |> T::from_double()
  let sr = @math.sin(half_roll) |> T::from_double()
  let cp = @math.cos(half_pitch) |> T::from_double()
  let sp = @math.sin(half_pitch) |> T::from_double()
  let cy = @math.cos(half_yaw) |> T::from_double()
  let sy = @math.sin(half_yaw) |> T::from_double()
  match order {
    "XYZ" =>
      Quaternion::{
        r: cr * cp * cy - sr * sp * sy,
        vec: (
          sr * cp * cy + cr * sp * sy,
          cr * sp * cy - sr * cp * sy,
          cr * cp * sy + sr * sp * cy,
        ),
      }
    "YXZ" =>
      Quaternion::{
        r: cr * cp * cy + sr * sp * sy,
        vec: (
          cy * sr * cp + cr * sp * sy,
          cy * cr * sp - sr * cp * sy,
          cr * cp * sy - sr * sp * cy,
        ),
      }
    "ZYX" =>
      Quaternion::{
        r: cy * cr * cp - sy * sr * sp,
        vec: (
          cy * sr * cp + cr * sp * sy,
          cy * cr * sp + sr * cp * sy,
          cr * cp * sy + sr * sp * cy,
        ),
      }
    "YZX" =>
      Quaternion::{
        r: cr * cp * cy - sr * sp * sy,
        vec: (
          sr * sp * cy + sy * cr * cp,
          sr * cp * cy + sp * sy * cr,
          sy * cr * cy - sr * sy * cp,
        ),
      }
    "ZXY" =>
      Quaternion::{
        r: cy * cr * cp - sy * sr * sp,
        vec: (
          sp * cr * cy - sr * sy * cp,
          sr * sp * cy + sy * cr * cp,
          sr * cp * cy + sp * sy * cr,
        ),
      }
    _ => abort("order error. Please check input format and retry")
  }
}

///|
test "from_euler" {
  inspect(
    from_euler(1.0, 1.0, 1.0, order="XYZ"),
    content="0.5656758145325667 + 0.5709414713577319i + 0.16751879124639693j + 0.5709414713577319k",
  )
  inspect(
    from_euler(0.0, @math.PI / 2, @math.PI / 2, order="YXZ"),
    content="0.5000000000000001 + 0.4999999999999999i + 0.5j + 0.5k",
  )
  inspect(
    from_euler(@math.PI / 2, 0.0, @math.PI / 2, order="ZYX"),
    content="0.5000000000000001 + 0.5i + 0.4999999999999999j + 0.5k",
  )
  inspect(
    from_euler(1.0, 1.0, 1.0, order="YZX"),
    content="0.5656758145325667 + 0.5709414713577319i + 0.5709414713577319j + 0.16751879124639693k",
  )
  inspect(
    from_euler(1.0, 1.0, 1.0, order="ZXY"),
    content="0.5656758145325667 + 0.16751879124639693i + 0.5709414713577319j + 0.5709414713577319k",
  )
}

///|
/// If the exponent isn't of type Int, please use the pow_by_T function to calculate.
/// Computes the power of a quaternion. Like q^2
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Sub + Div + Eq] Quaternion::pow_by_int(
  self : Quaternion[T],
  exponent : Int,
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
pub fn[T : @lg.Num + DoubleConvert + Mul + Add + Div + Eq] Quaternion::pow_by_T(
  self : Quaternion[T],
  exponent : T,
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
    let theta = 2.0 * @math.asin(v_norm)
    let new_angle = theta * exponent.to_double()
    let half_new_angle = new_angle / 2.0
    let new_len = len.to_double().pow(exponent.to_double()) |> T::from_double()
    let sin_half = @math.sin(half_new_angle) |> T::from_double()
    let cos_half = @math.cos(half_new_angle) |> T::from_double()
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
  inspect(q.pow_by_int(2), content="-25 + 8i + 12j + 16k")
  inspect(
    q.pow_by_T(2.0),
    content="-25.00000000000001 + 7.999999999999995i + 11.999999999999995j + 15.99999999999999k",
  )
}

/// convert quaternion to rotation matrix
// pub fn to_rotation_matrix[T](self : Quaternion[T]) -> Matrix[T] {
//    ...
// }
