# Changelog

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
