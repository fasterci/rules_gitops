"""
Implementation of external image information provider suitable for injection into manifests
"""

load("//gitops:provider.bzl", "GitopsPushInfo")

def _external_image_impl(ctx):
    sv = ctx.attr.image.split("@", 1)
    if (len(sv) == 1) and (not ctx.attr.digest):
        fail("digest must be specified either in image or as a separate attribute")
    s = sv[0].split(":", 1)[0]  #drop tag

    #write digest to a file
    digest_file = ctx.actions.declare_file(ctx.label.name + ".digest")
    ctx.actions.write(
        output = digest_file,
        content = ctx.attr.digest,
    )
    return [
        DefaultInfo(
            files = depset([digest_file]),
        ),
        GitopsPushInfo(
            image_label = ctx.label,
            repository = s,
            digestfile = digest_file,
        ),
    ]

external_image = rule(
    implementation = _external_image_impl,
    attrs = {
        "image": attr.string(mandatory = True, doc = "The image location, e.g. gcr.io/foo/bar:baz"),
        "digest": attr.string(mandatory = True, doc = "The image digest, e.g. sha256:deadbeef"),
    },
)
