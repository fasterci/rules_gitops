load("@rules_go//go:def.bzl", "go_binary")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

def go_image(
        name,
        embed,
        tars = [],
        goarch = "amd64",
        goos = "linux",
        gotags = [],
        pure = "on",
        package_dir = "",
        base = "@go_image_static",
        data = None,
        visibility = ["//visibility:public"]):
    """Emulate syntax of rules_gitops go_image."""
    go_binary(
        name = name + "_binary",
        embed = embed,
        data = data,
        goarch = goarch,
        goos = goos,
        gotags = gotags,
        pure = pure,
        visibility = visibility,
    )
    pkg_tar(
        name = name + "_tar",
        srcs = [":" + name + "_binary"],
        include_runfiles = True,
        visibility = visibility,
        package_dir = package_dir,
        strip_prefix = ".",
    )
    oci_image(
        name = name,
        base = base,
        entrypoint = ["/" + package_dir + name + "_binary_/" + name + "_binary"],
        tars = [":" + name + "_tar"] + tars,
        visibility = visibility,
    )
