load("@io_bazel_rules_go//go:def.bzl", "go_binary")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_oci//oci:defs.bzl", "oci_image")

def go_image(
        name,
        embed,
        tars = [],
        goarch = "amd64",
        goos = "linux",
        gotags = ["containers_image_openpgp"],
        pure = "on",
        symlinks = {},
        base = "@go_image_static",
        visibility = ["//visibility:public"]):
    """Emulate syntax of rules_gitops go_image."""
    go_binary(
        name = name + "_binary",
        embed = embed,
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
        symlinks = symlinks,
    )
    oci_image(
        name = name,
        base = base,
        entrypoint = ["/" + name + "_binary"],
        tars = [":" + name + "_tar"] + tars,
        visibility = visibility,
    )
