load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "anon.go",
        "auth.go",
        "authn.go",
        "basic.go",
        "bearer.go",
        "doc.go",
        "keychain.go",
        "multikeychain.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/authn",
    importpath = "github.com/google/go-containerregistry/pkg/authn",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/docker/cli/cli/config:go_default_library",
        "//vendor/github.com/docker/cli/cli/config/configfile:go_default_library",
        "//vendor/github.com/docker/cli/cli/config/types:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
        "//vendor/github.com/mitchellh/go-homedir:go_default_library",
    ],
)
