load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "compressed.go",
        "config.go",
        "encrypted_key.go",
        "literal.go",
        "ocfb.go",
        "one_pass_signature.go",
        "opaque.go",
        "packet.go",
        "private_key.go",
        "public_key.go",
        "public_key_v3.go",
        "reader.go",
        "signature.go",
        "signature_v3.go",
        "symmetric_key_encrypted.go",
        "symmetrically_encrypted.go",
        "userattribute.go",
        "userid.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/crypto/openpgp/packet",
    importpath = "golang.org/x/crypto/openpgp/packet",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/golang.org/x/crypto/cast5:go_default_library",
        "//vendor/golang.org/x/crypto/openpgp/elgamal:go_default_library",
        "//vendor/golang.org/x/crypto/openpgp/errors:go_default_library",
        "//vendor/golang.org/x/crypto/openpgp/s2k:go_default_library",
    ],
)
