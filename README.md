# quaternion

`Luna-Flow/quaternion` is a MoonBit library for Hamilton's quaternions $w + xi + yj + zk$. Unit quaternions represent 3D rotations that compose, invert and interpolate cheaply and have no gimbal lock, and general quaternions form a non-commutative ring. The library provides one generic type, `Quaternion[T]`, with ring arithmetic, right and left division, norms, vector rotation, spherical interpolation and Euler-angle conversion, and it plugs into the [luna-generic](https://github.com/Luna-Flow/luna-generic) algebraic traits.

## Installation

```sh
moon add Luna-Flow/quaternion@0.2.0
```

Then import `"Luna-Flow/quaternion"` in your package's `moon.pkg`. The library requires MoonBit with `moonc` 0.10 or later and depends on `Luna-Flow/luna-generic` 0.3.3.

## Example

```moonbit
fn main {
  // a quarter turn around the z axis
  let q = @quaternion.from_axis_angle((0.0, 0.0, 1.0), @math.PI / 2.0)
  let (x, y, _) = q.rotate((1.0, 0.0, 0.0))
  println("\{x.abs() < 1.0e-12}, \{y}") // true, 1
  // half of the turn, by spherical interpolation
  let half = @quaternion.slerp(@quaternion.id(), q, 0.5)
  println(half) // 0.9238795325112868 + 0i + 0j + 0.3826834323650898k
  // `/` is right division: (q / r) * r == q
  let r = @quaternion.Quaternion::from_vec((1.0, 2.0, 3.0, 4.0))
  println(((q / r) * r - q).square_len() < 1.0e-24) // true
}
```

The example imports `moonbitlang/core/math` for `@math.PI`.

## Package

| Package | Import path | Contents |
| --- | --- | --- |
| `core` (`src`) | `Luna-Flow/quaternion` | `Quaternion[T]`: arithmetic, `/` (right division) and `left_div`, `inv`, `conjugate`, norms, `rotate`, `slerp`, `from_axis_angle`, Euler-angle conversion, `DoubleConvert` |

`Quaternion[T]` implements luna-generic's `Zero`, `One`, `AddMonoid`, `MulMonoid`, `Semiring`, `Ring`, `Inverse` and `Conjugate`. It deliberately does not implement `Field`: quaternion multiplication is not commutative.

## Documentation

The manual, with API reference, tutorial and design notes (including derivations of the Hamilton product, the rotation formula and the Euler-angle conventions), is published at <https://lunaflow.cn/en/quaternion/> with Chinese and Japanese translations. Its English source is in [`doc/manual/`](doc/manual/index.md). The public interface is [`src/pkg.generated.mbti`](src/pkg.generated.mbti), and changes between versions are in [`CHANGELOG.md`](CHANGELOG.md).

## Contributing

Issues and pull requests are welcome at <https://github.com/Luna-Flow/quaternion>. Before opening a pull request, run:

```sh
moon fmt
moon check --target all
moon test --target all
moon info
```

and commit the regenerated `src/pkg.generated.mbti`. Documentation follows the Luna-Flow documentation standard: edit the English pages in `doc/manual/`, then update the translation catalogs with `lunadoc update`.

## License

Apache-2.0. See [LICENSE](LICENSE).
