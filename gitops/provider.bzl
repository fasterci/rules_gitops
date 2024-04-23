GitopsPushInfo = provider(
    "Information required to inject image into a manifest",
    fields = {
        "image_label": "bazel label of the image",
        "repository": "{registry}/{repository} without tag or sha part",
        "digestfile": "file with sha256 digest of the image. Combine {repository}@{digestfile content} to get full image name",
    },
)

# buildifier: disable=provider-params
GitopsArtifactsInfo = provider(
    """
    List of of executable targets required to be executed before deployment.
    Typically pushes images to a registry.
    """,
    fields = {
        "image_pushes": "List of of executable targets required to be executed before deployment, typically pushes images to a registry.",
        "deployment_branch": "Branch to merge manifests into and create a PR from.",
    },
)

AliasInfo = provider(
    "Alias for an image to be used in a manifest",
    fields = {
        "alias": "Alias for a target",
    },
)
