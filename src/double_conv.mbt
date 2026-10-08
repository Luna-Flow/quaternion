///|
pub trait DoubleConvert {
  fn to_double(Self) -> Double
  fn from_double(Double) -> Self
}

///|
pub impl DoubleConvert for Double with fn to_double(_) = "%identity"

///|
pub impl DoubleConvert for Double with fn from_double(_) = "%identity"

///|
pub impl DoubleConvert for Int with fn to_double(x) {
  x.to_double()
}

///|
pub impl DoubleConvert for Int with fn from_double(x) {
  x.to_int()
}
