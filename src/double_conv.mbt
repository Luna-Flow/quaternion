///|
pub trait DoubleConvert {
  to_double(Self) -> Double
  from_double(Double) -> Self
}

///|
impl DoubleConvert for Double with to_double(_) = "%identity"

///|
impl DoubleConvert for Double with from_double(_) = "%identity"

///|
impl DoubleConvert for Int with to_double(x) {
  x.to_double()
}

///|
impl DoubleConvert for Int with from_double(x) {
  x.to_int()
}
