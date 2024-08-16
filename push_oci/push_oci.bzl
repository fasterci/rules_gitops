"""
Implementation of the `k8s_push` rule based on rules_oci
"""

load("@bazel_skylib//rules:write_file.bzl", "write_file")

# TODO: remove this once rules_oci is updated
# buildifier: disable=bzl-visibility
load("@rules_oci//oci/private:push.bzl", "oci_push_lib")
load("//gitops:provider.bzl", "GitopsPushInfo")
load("//skylib:runfile.bzl", "get_runfile_path")

def _impl(ctx):
    if GitopsPushInfo in ctx.attr.image:
        # the image was already pushed, just rename if needed. Ignore registry and repository parameters
        kpi = ctx.attr.image[GitopsPushInfo]
        if ctx.attr.image[DefaultInfo].files_to_run.executable:
            ctx.actions.expand_template(
                template = ctx.file._tag_tpl,
                substitutions = {
                    "%{args}": "",
                    "%{container_pusher}": get_runfile_path(ctx, ctx.attr.image[DefaultInfo].files_to_run.executable),
                },
                output = ctx.outputs.executable,
                is_executable = True,
            )
        else:
            ctx.actions.write(
                content = "#!/bin/bash\n",
                output = ctx.outputs.executable,
                is_executable = True,
            )

        runfiles = ctx.runfiles(files = []).merge(ctx.attr.image[DefaultInfo].default_runfiles)

        digest = ctx.actions.declare_file(ctx.attr.name + ".digest")
        ctx.actions.run_shell(
            tools = [kpi.digestfile],
            outputs = [digest],
            command = "cp -f \"$1\" \"$2\"",
            arguments = [kpi.digestfile.path, digest.path],
            mnemonic = "CopyFile",
            use_default_shell_env = True,
            execution_requirements = {
                "no-remote": "1",
                "no-remote-cache": "1",
                "no-remote-exec": "1",
                "no-cache": "1",
                "no-sandbox": "1",
                "local": "1",
            },
        )

        return [
            # we need to provide executable that calls the actual pusher
            DefaultInfo(
                executable = ctx.outputs.executable,
                runfiles = runfiles,
            ),
            GitopsPushInfo(
                image_label = kpi.image_label,
                repository = kpi.repository,
                digestfile = digest,
            ),
        ]

    default_info = oci_push_lib.implementation(ctx = ctx)

    jq_bin = ctx.toolchains["@aspect_bazel_lib//lib:jq_toolchain_type"].jqinfo.bin
    digest = ctx.actions.declare_file(ctx.attr.name + ".digest")
    ctx.actions.run_shell(
        inputs = [ctx.file.image],
        outputs = [digest],
        arguments = [jq_bin.path, ctx.file.image.path, digest.path],
        command = "${1} --raw-output '.manifests[].digest' ${2}/index.json > ${3}",
        progress_message = "Extracting digest from %s" % ctx.file.image.short_path,
        tools = [jq_bin],
    )

    return [
        default_info,
        GitopsPushInfo(
            image_label = ctx.attr.image.label,
            # registry = registry,
            repository = ctx.attr.repository,
            digestfile = digest,
        ),
    ]

push_oci_rule = rule(
    implementation = _impl,
    attrs = oci_push_lib.attrs |
            {"_tag_tpl": attr.label(
                default = Label("//push_oci:tag.sh.tpl"),
                allow_single_file = True,
            )},
    toolchains = ["@aspect_bazel_lib//lib:jq_toolchain_type"] + oci_push_lib.toolchains,
    executable = True,
    # provides = [GitopsPushInfo, DefaultInfo],
)

def push_oci(
        name,
        image,
        repository,
        registry = None,
        image_digest_tag = False,  # buildifier: disable=unused-variable either remove parameter or implement
        tag = None,
        remote_tags = None,  # file with tags to push
        tags = [],  # bazel tags to add to the push_oci_rule
        visibility = None):
    if tag:
        tags_label = "_{}_write_tags".format(name)
        write_file(
            name = tags_label,
            out = "_{}.tags.txt".format(name),
            content = remote_tags,
        )
        remote_tags = tags_label

    if not repository:
        label = native.package_relative_label(image)
        repository = "{}/{}".format(label.package, label.name)
    if registry:
        repository = "{}/{}".format(registry, repository)
    push_oci_rule(
        name = name,
        image = image,
        repository = repository,
        remote_tags = remote_tags,
        tags = tags,
        visibility = visibility,
    )
