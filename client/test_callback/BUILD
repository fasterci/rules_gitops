load("@io_bazel_rules_go//go:def.bzl", "go_test")

go_test(
    name = "go_default_test",
    srcs = ["sidecar_client_test.go"],
    args = [
        "-setup",
        "$(location //client:noop.setup)",
    ],
    data = [
        "//client:noop.setup",
    ],
    rundir = ".",
    deps = ["//client:go_default_library"],
)
