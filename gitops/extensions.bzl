"""Extensions for bzlmod.

TODO: implement a proper toolchain resolution mechanism in bzlmod
"""

load(
    ":repositories.bzl",
    "DEFAULT_KUSTOMIZE_REPOSITORY",
    "DEFAULT_KUSTOMIZE_VERSION",
    "register_kustomize_toolchains",
)
load("//gitops/private:extension_utils.bzl", "extension_utils")
load("//gitops/private:host_repo.bzl", "host_repo")

def _host_extension_impl(mctx):
    create_host_repo = False
    for module in mctx.modules:
        if len(module.tags.host) > 0:
            create_host_repo = True

    if create_host_repo:
        host_repo(name = "gitops_host")

host = module_extension(
    implementation = _host_extension_impl,
    tag_classes = {
        "host": tag_class(attrs = {}),
    },
)

def _toolchains_extension_impl(mctx):
    extension_utils.toolchain_repos_bfs(
        mctx = mctx,
        get_tag_fn = lambda tags: tags.kustomize,
        toolchain_name = "kustomize",
        toolchain_repos_fn = lambda name, version: register_kustomize_toolchains(name = name, version = version, register = False),
    )

toolchains = module_extension(
    implementation = _toolchains_extension_impl,
    tag_classes = {"kustomize": tag_class(
        attrs = {
            "name": attr.string(doc = "Kustomize binary repository name", default = DEFAULT_KUSTOMIZE_REPOSITORY),
            "version": attr.string(default = DEFAULT_KUSTOMIZE_VERSION),
        },
    )},
)
