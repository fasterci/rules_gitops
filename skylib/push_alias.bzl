"""
Implementation of the wrapper that would add an alias to a pushed image.
Provides a legacy interface for using short aliases for images instead of the full bazel target path.
Using aliases in new code is not recommended, as it creates a unnecessary level of indirection.
"""

load("//gitops:provider.bzl", "AliasInfo", "GitopsPushInfo")

def _push_alias_impl(ctx):
    default_info = ctx.attr.pushed_image[DefaultInfo]
    files = default_info.files
    new_executable = None
    original_executable = default_info.files_to_run.executable
    runfiles = default_info.default_runfiles

    new_executable = ctx.outputs.executable

    ctx.actions.symlink(
        output = new_executable,
        target_file = original_executable,
        is_executable = True,
    )
    files = depset(direct = [new_executable], transitive = [files])
    runfiles = runfiles.merge(ctx.runfiles([new_executable]))

    return [
        DefaultInfo(
            files = files,
            runfiles = runfiles,
            executable = new_executable,
        ),
        ctx.attr.pushed_image[GitopsPushInfo],
        AliasInfo(
            alias = ctx.attr.alias,
        ),
    ]

pushed_image_alias = rule(
    implementation = _push_alias_impl,
    attrs = {
        "pushed_image": attr.label(mandatory = True, providers = (GitopsPushInfo,), doc = "The pushed image like k8s_image_push"),
        "alias": attr.string(mandatory = True, doc = "The alias to be added to the pushed image"),
    },
    executable = True,
)
