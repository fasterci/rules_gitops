"""
Implementation of the `k8s_push` rule based on rules_oci and rules_img
"""

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_img//img:providers.bzl", "ImageIndexInfo", "ImageManifestInfo")

# TODO: remove this once rules_oci is updated
# buildifier: disable=bzl-visibility
load("@rules_oci//oci/private:push.bzl", "oci_push_lib")
load("//gitops:provider.bzl", "GitopsPushInfo")
load("//skylib:runfile.bzl", "get_runfile_path")

def _gitops_image_adapter_impl(ctx):
    providers = []
    
    # Forward ImageManifestInfo/ImageIndexInfo/GitopsPushInfo/OutputGroupInfo if present
    if ImageManifestInfo in ctx.attr.image:
        providers.append(ctx.attr.image[ImageManifestInfo])
    if ImageIndexInfo in ctx.attr.image:
        providers.append(ctx.attr.image[ImageIndexInfo])
    if GitopsPushInfo in ctx.attr.image:
        providers.append(ctx.attr.image[GitopsPushInfo])
    if OutputGroupInfo in ctx.attr.image:
        providers.append(ctx.attr.image[OutputGroupInfo])
        
    # Forward the single file/directory for oci_push_lib compatibility
    files_list = ctx.files.image
    single_file = files_list[0] if files_list else None
    
    executable = ctx.attr.image[DefaultInfo].files_to_run.executable
    dummy_exe = ctx.actions.declare_file(ctx.label.name + ".exe")
    if executable:
        # Wrap the original executable in our own generated script
        ctx.actions.expand_template(
            template = ctx.file._tag_tpl,
            substitutions = {
                "%{args}": "",
                "%{container_pusher}": get_runfile_path(ctx, executable),
            },
            output = dummy_exe,
            is_executable = True,
        )
        # Also ensure original executable is in runfiles so it is packaged!
        runfiles = ctx.runfiles(files = [executable]).merge(ctx.attr.image[DefaultInfo].default_runfiles)
    else:
        ctx.actions.write(
            content = "#!/bin/bash\n",
            output = dummy_exe,
            is_executable = True,
        )
        runfiles = ctx.attr.image[DefaultInfo].default_runfiles
        
    providers.append(DefaultInfo(
        files = depset([single_file]) if single_file else depset(),
        runfiles = runfiles,
        executable = dummy_exe,
    ))
    return providers

gitops_image_adapter = rule(
    implementation = _gitops_image_adapter_impl,
    attrs = {
        "image": attr.label(mandatory = True),
        "_tag_tpl": attr.label(
            default = Label("//push_oci:tag.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
)

def _impl(ctx):
    # Resolve the original image label
    orig_image_label = ctx.attr.image_label.label if ctx.attr.image_label else ctx.attr.image.label

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
                image_label = orig_image_label,
                repository = kpi.repository,
                digestfile = digest,
            ),
        ]

    # Detect rules_img image manifest / index
    if ImageIndexInfo in ctx.attr.image or ImageManifestInfo in ctx.attr.image:
        # Write dummy script since pushing is external
        ctx.actions.write(
            content = "#!/bin/bash\necho 'push_img target executed (handled externally)'\n",
            output = ctx.outputs.executable,
            is_executable = True,
        )

        # Extract digest directly from rules_img's OutputGroupInfo.digest
        digest = ctx.attr.image[OutputGroupInfo].digest.to_list()[0]

        return [
            DefaultInfo(
                executable = ctx.outputs.executable,
            ),
            GitopsPushInfo(
                image_label = orig_image_label,
                repository = ctx.attr.repository,
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
            image_label = orig_image_label,
            # registry = registry,
            repository = ctx.attr.repository,
            digestfile = digest,
        ),
    ]

push_oci_rule = rule(
    implementation = _impl,
    attrs = oci_push_lib.attrs | {
        "image_label": attr.label(mandatory = False),
        "_tag_tpl": attr.label(
            default = Label("//push_oci:tag.sh.tpl"),
            allow_single_file = True,
        ),
    },
    toolchains = ["@aspect_bazel_lib//lib:jq_toolchain_type"] + oci_push_lib.toolchains,
    executable = True,
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
    """Pushes an OCI or rules_img container image to a registry.

    Args:
        name: Name of the target.
        image: Label of the image target.
        repository: Repository path to push to.
        registry: Optional registry domain.
        image_digest_tag: Unused compatibility tag.
        tag: Optional string tag.
        remote_tags: Optional file with tags.
        tags: Optional Bazel tags.
        visibility: Optional target visibility.
    """
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

    # Instantiate the single-file/directory image adapter
    adapter_name = name + ".adapter"
    gitops_image_adapter(
        name = adapter_name,
        image = image,
        visibility = ["//visibility:private"],
    )

    push_oci_rule(
        name = name,
        image = ":" + adapter_name,
        image_label = image,
        repository = repository,
        remote_tags = remote_tags,
        tags = tags,
        visibility = visibility,
    )
