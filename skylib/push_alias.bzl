"""
Implementation of the wrapper that would add an alias to a pushed image.
Provides a legacy interface for using short aliases for images instead of the full bazel target path.
Using aliases in new code is not recommended, as it creates a unnecessary level of indirection.
"""

load("//gitops:provider.bzl", "GitopsPushInfo")

def _push_alias_impl(ctx):
    #write digest to a file
    return [
        ctx.attr.pushed_image[DefaultInfo],
        ctx.attr.pushed_image[GitopsPushInfo],
        AliasInfo(
            alias = ctx.attr.alias,
        ),
    ]

pushed_iamge_alias = rule(
    implementation = _push_alias_impl,
    attrs = {
        "pushed_image": attr.label(mandatory = True, providers = (GitopsPushInfo,), doc = "The pushed image like k8s_image_push"),
        "alias": attr.string(mandatory = True, doc = "The alias to be added to the pushed image"),
    },
)
