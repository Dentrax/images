<!--monopod:start-->
# busybox
| | |
| - | - |
| **Status** | stable |
| **OCI Reference** | `cgr.dev/chainguard/busybox` |
| **Variants/Tags** | ![](https://storage.googleapis.com/chainguard-images-build-outputs/summary/busybox.svg) |

*[Contact Chainguard](https://www.chainguard.dev/chainguard-images) for enterprise support, SLAs, and access to older tags.*

---
<!--monopod:end-->

Container image with only busybox and libc (available in both musl and glibc variants). Suitable for running any binaries that only have a dependency on glibc/musl.

- [Documentation](https://edu.chainguard.dev/chainguard/chainguard-images/reference/busybox)
- [Usage](https://github.com/chainguard-images/images/blob/main/images/busybox/README.md#usage)
- [Provenance Information](https://edu.chainguard.dev/chainguard/chainguard-images/reference/busybox/provenance_info/)

## Image Variants

There are two variants, one for musl and one for gclib.

- `latest`: This is a image that has busybox and is for musl based variants.
- `latest-glibc`: This is a image that has busybox and is for glibc based variants.

## Get It!

The image is available on `cgr.dev`:

```shell
docker pull cgr.dev/chainguard/busybox:latest
```

## Usage

We are going to run a simple hello world to make sure things are working either on the musl or glibc one:

`musl`:
```shell
docker run -it cgr.dev/chainguard/busybox:latest echo hello world!
```

`glibc`:
```shell
docker run -it cgr.dev/chainguard/busybox:latest-glibc echo hello world!
```

and you should see `hello world!` printed.

You can get a running shell on the image like this:

```shell
docker run -it cgr.dev/chainguard/busybox:latest sh
```
