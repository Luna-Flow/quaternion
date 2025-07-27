///|
pub trait DoubleConvert {
  to_double(Self) -> Double
  from_double(Double) -> Self
}

///|
pub impl DoubleConvert for Double with to_double(_) = "%identity"

///|
pub impl DoubleConvert for Double with from_double(_) = "%identity"

///|
pub impl DoubleConvert for Int with to_double(x) {
  x.to_double()
}

///|
pub impl DoubleConvert for Int with from_double(x) {
  x.to_int()
}
