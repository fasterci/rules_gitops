load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "armor.go",
        "encode.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/crypto/openpgp/armor",
    importpath = "golang.org/x/crypto/openpgp/armor",
    visibility = ["//visibility:public"],
    deps = ["//vendor/golang.org/x/crypto/openpgp/errors:go_default_library"],
)
