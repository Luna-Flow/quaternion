# Changelog

## Unreleased

### Changed

- `Luna-Flow/luna-generic` is bumped from 0.3.3 to 0.4.0. The package uses only `Zero`, `One`, `Num`, `AddMonoid`, `MulMonoid`, `Semiring`, `Ring`, `Conjugate` and `Inverse`, none of which changed, so no code change is needed and nothing deprecated in 0.4.0 is used. `Quaternion::inv` divides by the squared norm and does not call `Float::inv` or `Double::inv`, so the new abort on zero in those instances does not reach it.

### Documentation

- The manual follows the luna-generic layout: the overview has Install, Pages, exported items and reading paths; the API page has Purpose and Importing sections; the tutorial starts with a task table and a checked quick start; the design page states its constraints.
- Logic review of the manual. New derivations: what `rotate` returns for a non-unit quaternion ($\mathbf v + |q|^2(R(\hat q)\mathbf v - \mathbf v)$, which replaces the claim that a drifted quaternion scales vectors) and the nlerp error bound $\Omega^3\sqrt 3/108$ behind the `slerp` threshold.
- Newly documented known issues: `pow_by_T` returns NaN for some pure quaternions, `pow_by_int(-2147483648)` never returns, the gimbal-lock branch of extrinsic XYZ always returns a first angle of $\pm\pi/4$ or $\pm3\pi/4$ and drops a still-determined third angle, and `Quaternion[Quaternion[T]]` is a `Ring` instance whose multiplication is not associative.

## 0.2.0

### Breaking

- `q / r` is now **right division** (`q * r.inv()`, the solution of `x * r == q`). It previously computed left division (`r.inv() * q`). Use the new `Quaternion::left_div` for the old behaviour.
- Requires MoonBit with `moonc` 0.10 or later and `Luna-Flow/luna-generic` 0.3.3 (previously 0.2.1).

### Added

- `Quaternion[T]` implements luna-generic `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring` and `Ring` (for `T : Ring`). `Field` is intentionally not implemented because quaternion multiplication is not commutative.
- `Quaternion::left_div`, `Quaternion::zero()`, `Quaternion::one()`.
- `Quaternion` derives `Debug`, so it works with `assert_eq` / `debug_inspect`.

### Changed

- Migrated to MoonBit 0.10 (`moon.mod` / `moon.pkg` replace `moon.mod.json` / `moon.pkg.json`, explicit method promotion in `extends.mbt`) and luna-generic 0.3.3.
- Methods are promoted explicitly: the operators (`add`, `sub`, `mul`, `div`, `neg`), `equal`, `hash`, `to_string`, `conjugate`, `inv`, `zero` and `one` are callable as methods.
- `not_equal`, `hash_combine`, `Show::output`, `Default::default` and `Debug::to_repr` method forms are deprecated; use the operators, `id()`, `Repr(x)` or string interpolation.
- The deprecated `op_add`, `op_sub`, `op_mul`, `op_div`, `op_neg` and `op_equal` method aliases are no longer exported; use the operators or `add`, `sub`, `mul`, `div`, `neg`, `equal`.

### Documentation

- Documentation rewritten as API reference, tutorial and design pages, with derivations of the Hamilton product, the norm and inverse, right and left division, the rotation formula, slerp and the Euler-angle extraction, and with zh_CN and ja_JP translations.
- The manual lists known issues of the Euler-angle conversions (`from_euler` orders `"ZYX"`/`"YZX"`, `to_euler` extrinsic `"XZY"`/intrinsic `"YZX"`, the gimbal-lock branch) and of `pow_by_T` for quaternions with a negative scalar part.
- Corrected the doc comments of the `to_euler_internal_*` functions, which all named the XZY order.
