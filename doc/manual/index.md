# quaternion

`quaternion` is the Luna-Flow library for Hamilton's quaternions $\mathbb H$: the four-dimensional number system $w + xi + yj + zk$ in which $i^2 = j^2 = k^2 = ijk = -1$. Unit quaternions describe 3D rotations without the singularities of Euler angles, and they compose, invert and interpolate cheaply. The library provides one generic type, `Quaternion[T]`, with ring arithmetic, right and left division, norms, rotation of vectors, spherical interpolation and Euler-angle conversion.

## Packages

The module `Luna-Flow/quaternion` has a single package at the source root `src`, documented as `core`:

| Package | Import path | Contents | Pages |
| --- | --- | --- | --- |
| `core` | `Luna-Flow/quaternion` | `Quaternion[T]`, its arithmetic and rotation functions, the `DoubleConvert` trait | [API](api/core.md) · [tutorial](tutorial/core.md) · [design](design/core.md) |

The sources are [`src/quaternion.mbt`](../../src/quaternion.mbt) (the type and all operations), [`src/double_conv.mbt`](../../src/double_conv.mbt) (`DoubleConvert`) and [`src/extends.mbt`](../../src/extends.mbt) (which trait methods are callable as methods). The generated interface [`src/pkg.generated.mbti`](../../src/pkg.generated.mbti) lists every public signature.

## At a glance

- `Quaternion[T]` is generic in its component type. Ring operations work over exact types such as `Int`; functions that need square roots or trigonometry compute in `Double` through `DoubleConvert`, which is implemented for `Int` and `Double`.
- `+`, `-`, unary `-` and `*` (the Hamilton product) are the usual operations. `*` is not commutative.
- `q / r` is right division $q\,r^{-1}$; `q.left_div(r)` is left division $r^{-1} q$. Before 0.2.0, `/` computed $r^{-1} q$.
- The type implements luna-generic's `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring`, `Ring`, `Inverse` and `Conjugate`. It does not implement `Field`, because multiplication is not commutative.
- Rotations: `from_axis_angle`, `from_euler`, `Quaternion::rotate`, `slerp`, `Quaternion::to_euler` and its eight fixed-order variants.

## Where to start

- **New to quaternions:** read the [tutorial](tutorial/core.md) from the quick start to "Compare two rotations". It needs no mathematics beyond vectors and angles.
- **Using the library:** the [API reference](api/core.md) lists every function with its exact signature, conventions, edge cases and known issues. Check the Euler-angle conventions there before converting angles.
- **Contributing or reviewing:** the [design page](design/core.md) derives the Hamilton product, the rotation formula, division, slerp and the Euler-angle extraction from Hamilton's relations, explains each design decision, and lists the places where the implementation currently deviates from the mathematics.

## Installation and toolchain

The library needs MoonBit with `moonc` 0.10 or later and depends on `Luna-Flow/luna-generic` 0.3.3. Add it to a module with:

```sh
moon add Luna-Flow/quaternion@0.2.0
```

and import `"Luna-Flow/quaternion"` in the `moon.pkg` of the package that uses it. The code is target-independent and is tested on the `wasm`, `wasm-gc`, `js` and `native` backends.

## Validation

From the repository root:

```sh
moon check --target all
moon test --target all
moon info
```

`moon info` regenerates `src/pkg.generated.mbti`; a change in that file is a change of the public API.
