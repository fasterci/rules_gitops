"""Extensions for bzlmod.

TODO: implement a proper toolchain resolution mechanism in bzlmod
"""

load("@rules_gitops//skylib/kustomize:kustomize.bzl", "kustomize_setup")

kustomize_toolchain = tag_class(attrs = {
    "name": attr.string(doc = """\
Base name for generated repositories, allowing more than one kustomize toolchain to be registered.
Overriding the default is only permitted in the root module.
""", default = "kustomize_bin"),
    # "kustomize_version": attr.string(doc = "Explicit version of kustomize.", mandatory = True),
})

def _toolchain_extension(module_ctx):
    kustomize_setup(name = "kustomize_bin")

kustomize = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {"toolchain": kustomize_toolchain},
)
