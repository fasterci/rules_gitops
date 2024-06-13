"Public API"

load("@rules_gitops//gitops:provider.bzl", "GitopsPushInfo")
load("@rules_gitops//skylib:runfile.bzl", "get_runfile_path")

def _replace_colon_except_last_segment(input_string):
    segments = input_string.split("/")
    for i in range(len(segments) - 1):
        segments[i] = segments[i].replace(":", "")
    output_string = "/".join(segments)
    return output_string

def _mirror_image_impl(ctx):
    digest = ctx.attr.digest
    src_image = ctx.attr.src_image
    v = src_image.split("@", 1)
    s = v[0]
    if len(v) > 1:
        # If the image has a digest, use that.
        if digest and v[1] != digest:
            fail("digest mismatch: %s != %s" % (v[1], digest))
        digest = v[1]
    else:
        # If the image does not have a digest, use the one provided.
        src_image = s + "@" + digest

    if not digest:
        fail("digest must be provided as an attribute to mirror_image or in the src_image")

    dst_without_hash = ""
    if ctx.attr.dst:
        dst = ctx.expand_make_variables("dst", ctx.attr.dst, {})
        dst = dst.split("@", 1)[0]
        dst_without_hash = _replace_colon_except_last_segment(dst)
    else:
        if not ctx.attr.dst_prefix:
            fail("either dst or dst_prefix must be defined in mirror_image")
        src_repository = _replace_colon_except_last_segment(s)
        dst_prefix = ctx.expand_make_variables("dst_prefix", ctx.attr.dst_prefix, {})
        dst_without_hash = dst_prefix.strip("/") + "/" + src_repository

    digest_file = ctx.actions.declare_file(ctx.label.name + ".digest")
    ctx.actions.write(
        output = digest_file,
        content = digest,
    )

    pusher_input = [digest_file]

    ctx.actions.expand_template(
        template = ctx.file._mirror_image_script,
        output = ctx.outputs.executable,
        substitutions = {
            "{mirror_tool}": get_runfile_path(ctx, ctx.executable.mirror_tool),
            "{src_image}": src_image,
            "{digest}": digest,
            "{dst_image}": dst_without_hash,
            "{timeout}": ctx.attr.push_timeout,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = pusher_input).merge(ctx.attr.mirror_tool[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            runfiles = runfiles,
            executable = ctx.outputs.executable,
        ),
        GitopsPushInfo(
            image_label = ctx.label,
            repository = dst_without_hash,
            digestfile = digest_file,
        ),
    ]

mirror_image_rule = rule(
    implementation = _mirror_image_impl,
    attrs = {
        "src_image": attr.string(
            mandatory = True,
            doc = "The image to mirror",
        ),
        "image_name": attr.string(
            doc = "The name that could be referred in manifests. This field is deprecated and unused.",
        ),
        "digest": attr.string(
            mandatory = False,
            doc = "The digest of the image. If not provided, it will be extracted from the src_image.",
        ),
        "dst_prefix": attr.string(
            doc = "The prefix of the destination image, should include the registry and repository. Either dst_prefix or dst_image must be specified.",
        ),
        "dst": attr.string(
            doc = "The destination image location, should include the registry and repository. Either dst_prefix or dst_image must be specified.",
        ),
        "push_timeout": attr.string(
            doc = "The allowed wait time for image pushes",
            default = "30s",
        ),
        "mirror_tool": attr.label(
            default = Label("//mirror/cmd/mirror"),
            executable = True,
            cfg = "exec",
        ),
        "_mirror_image_script": attr.label(
            default = ":mirror_image.sh",
            allow_single_file = True,
        ),
    },
    executable = True,
    doc = """Mirror an image to a local registry. 
Implements GitopsPushInfo and K8sPushInfo providers so the returned image can be injected into manifests by rules_gitops
""",
)

def validate_image_test(name, image, digest, tags = [], **kwargs):
    """
    Create a test that validates the image existance using crane validate.
    Image tag will be ignored if provided and only the digest will be used.
    if digest is provided as a part of the image, it will be used.
    It is an error to provide both digest and image with digest if they do not match.
    """
    src_image = image
    v = src_image.split("@", 1)
    s = v[0]
    if len(v) > 1:
        # If the image has a digest, use that.
        if digest and v[1] != digest:
            fail("digest mismatch: %s != %s" % (v[1], digest))
        digest = v[1]
    else:
        # If the image does not have a digest, use the one provided.
        src_image = s + "@" + digest

    if not digest:
        fail("digest must be provided as an attribute to mirror_image or in the src_image")

    native.sh_test(
        name = name,
        size = "small",
        srcs = ["@rules_gitops//mirror:validate_image.sh"],
        data = [
            "@rules_gitops//vendor/github.com/google/go-containerregistry/cmd/crane:crane",
        ],
        args = [
            src_image,
        ],
        tags = ["requires-network"] + tags,
        env = {
            "CRANE_BIN": "$(location @rules_gitops//vendor/github.com/google/go-containerregistry/cmd/crane:crane)",
        },
        **kwargs
    )

def mirror_image(name, src_image, digest, tags = [], **kwargs):
    visibility = kwargs.pop("visibility", None)
    mirror_image_rule(name = name, src_image = src_image, digest = digest, tags = tags, visibility = visibility, **kwargs)
    validate_image_test(name = name + "_validate_src", image = src_image, digest = digest, visibility = visibility, tags = tags)
