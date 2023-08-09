"""
Implementation of the `k8s_push` rule based on rules_oci
"""

load("//gitops:provider.bzl", "K8sPushInfo")
load("@rules_oci//oci/private:push.bzl", "oci_push_lib")

def _impl(ctx):
    yq_bin = ctx.toolchains["@aspect_bazel_lib//lib:yq_toolchain_type"].yqinfo.bin

    default_info = oci_push_lib.implementation(
        ctx = ctx,
    )

    ctx.actions.run_shell(
        inputs = [ctx.file.image],
        outputs = [ctx.outputs.digest],
        arguments = [yq_bin.path, ctx.file.image.path, ctx.outputs.digest.path],
        command = "${1} '.manifests[].digest' ${2}/index.json > ${3}",
        progress_message = "Extracting digest from %s" % ctx.file.image.short_path,
        tools = [yq_bin],
        # toolchain = "@aspect_bazel_lib//lib:yq_toolchain_type",
    )

    return [
        default_info,
        K8sPushInfo(
            image_label = ctx.attr.image.label,
            # registry = registry,
            repository = ctx.attr.repository,
            digestfile = ctx.outputs.digest,
        ),
    ]

push_oci_rule = rule(
    implementation = _impl,
    attrs = oci_push_lib.attrs,
    toolchains = oci_push_lib.toolchains,
    executable = True,
    outputs = {
        "digest": "%{name}.digest",
    },
    # provides = [K8sPushInfo, DefaultInfo],
)

def push_oci(
        name,
        image,
        repository = "",
        registry = "gcr.io",
        image_digest_tag = False,
        digestfile = None,
        visibility = None):
    if repository == "":
        repository = native.package_relative_label(image).package
    push_oci_rule(
        name = name,
        image = image,
        repository = repository,
        digestfile = digestfile,
        visibility = visibility,
    )
