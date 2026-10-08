# quaternion

This manual documents the `v0.2.0` release of `Luna-Flow/quaternion`.

## Overview

`quaternion` is the Luna-Flow library for Hamilton's quaternions $\mathbb H$: the four-dimensional number system $w + xi + yj + zk$ in which $i^2 = j^2 = k^2 = ijk = -1$. Unit quaternions describe 3D rotations without the singularities of Euler angles, and they compose, invert and interpolate cheaply. The library provides one generic type, `Quaternion[T]`, with ring arithmetic, right and left division, norms, rotation of vectors, spherical interpolation and Euler-angle conversion.

The 0.2.0 release centers on three changes:

- `q / r` is right division $q\,r^{-1}$; the old left quotient $r^{-1} q$ is now `Quaternion::left_div`.
- `Quaternion[T]` implements luna-generic's `Ring` (and the traits below it), but not `Field`, because multiplication is not commutative.
- The package builds with MoonBit 0.10 and promotes trait methods explicitly.

## Install

```bash
moon add Luna-Flow/quaternion@0.2.0
```

Then import `"Luna-Flow/quaternion"` in your `moon.pkg`. The package needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10) and depends on `Luna-Flow/luna-generic` 0.3.3. The code is target-independent and is tested on the `wasm`, `wasm-gc`, `js` and `native` backends.

## Pages

The repository is one MoonBit package at `src`, documented as `core`. Its sources are [`src/quaternion.mbt`](../../src/quaternion.mbt) (the type and all operations), [`src/double_conv.mbt`](../../src/double_conv.mbt) (`DoubleConvert`) and [`src/extends.mbt`](../../src/extends.mbt) (which trait methods are callable as methods). The generated interface [`src/pkg.generated.mbti`](../../src/pkg.generated.mbti) lists every public signature.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: `Quaternion[T]`, arithmetic, rotations, `DoubleConvert` | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |

## Exported type and trait

- `Quaternion[T]`: the quaternion $w + xi + yj + zk$ with components of type `T`, abstract, with derived `Eq`, `Hash` and `Debug`
- `DoubleConvert`: the bridge to `Double` used by every function that needs square roots or trigonometry; implemented for `Int` and `Double`

## Arithmetic

- Construction: `Quaternion::from_vec`, `id`, `Quaternion::zero`, `Quaternion::one`
- Operators: `+`, `-`, unary `-`, `*` (the Hamilton product, not commutative), `/` (right division)
- `Quaternion::left_div`, `Quaternion::scale`, `Quaternion::conjugate`, `Quaternion::inv`
- Powers: `Quaternion::pow_by_int`, `Quaternion::pow_by_T`
- Norms: `Quaternion::dot`, `Quaternion::square_len`, `Quaternion::magnitude`, `Quaternion::normalize`
- luna-generic instances: `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring`, `Ring`, `Inverse`, `Conjugate`

## Rotations

- `from_axis_angle`, `from_euler`: build a unit quaternion
- `Quaternion::rotate`: apply it to a vector
- `slerp`: interpolate between two orientations
- `Quaternion::to_euler` and its eight fixed-order variants: decompose into Euler angles

Several Euler-angle orders, the gimbal-lock branch and `pow_by_T` have known issues; the [API](api/core.md) marks each with a warning.

## Where to read next

The [core tutorial](tutorial/core.md) rotates, composes, compares and interpolates orientations. The [core API](api/core.md) lists every function with its exact signature, conventions and edge cases, and the [core design](design/core.md) derives the Hamilton product, the rotation formula, division, slerp and the Euler-angle extraction from Hamilton's relations.

- New to quaternions: read the [tutorial](tutorial/core.md) from the quick start to "Compare two rotations". It needs no mathematics beyond vectors and angles.
- Using it in a library: keep the [API](api/core.md) at hand, and check the Euler-angle conventions and the warnings there before converting angles.
- Contributing: read the [design](design/core.md), in particular its list of known deviations, before changing an operation.

## Validation

Recommended release checks, from the repository root:

```bash
moon check --target all
moon test --target all
moon info
```

`moon info` regenerates `src/pkg.generated.mbti`; a change in that file is a change of the public API.
