// Explicit trait-method promotions (see core AGENTS.md "Trait-method promotion").

///|
pub extend Quaternion with Add::{add}

///|
pub extend Quaternion with Sub::{sub}

///|
pub extend Quaternion with Mul::{mul}

///|
pub extend Quaternion with Div::{div}

///|
pub extend Quaternion with Neg::{neg}

///|
pub extend Quaternion with Eq::{equal}

///|
pub extend Quaternion with Hash::{hash}

///|
/// `a + bi + cj + dk` is the canonical text form of a quaternion.
pub extend Quaternion with Show::{to_string}

///|
/// The quaternion conjugate `r - xi - yj - zk`.
pub extend Quaternion with @lg.Conjugate::{conjugate}

///|
/// `Quaternion::zero()` is the additive identity.
pub extend Quaternion with @lg.Zero::{zero}

///|
/// `Quaternion::one()` is the multiplicative identity.
pub extend Quaternion with @lg.One::{one}

///|
/// The two-sided multiplicative inverse `conj(q) / |q|^2`.
pub extend Quaternion with @lg.Inverse::{inv}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Quaternion with Eq::{not_equal}

///|
#deprecated("Use `Hash::hash_combine` via the trait instead", skip_current_package=true)
#doc(hidden)
pub extend Quaternion with Hash::{hash_combine}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Quaternion with Show::{output}

///|
#deprecated("Use `id()` or `Default::default()` instead", skip_current_package=true)
#doc(hidden)
pub extend Quaternion with Default::{default}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Quaternion with @debug.Debug::{to_repr}
