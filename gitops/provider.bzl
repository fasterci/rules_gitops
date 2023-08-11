K8sPushInfo = provider(
    "Information required to inject image into a manifest",
    fields = [
        "image_label",  # bazel target label of the image
        # "legacy_image_name",  # DEPRECATED AND REMOVED short name
        # "registry",
        "repository",
        "digestfile",
    ],
)

# buildifier: disable=provider-params
GitopsArtifactsInfo = provider(fields = [
    """
    List of of executable targets required to be executed before deployment. Typically pushes images to a registry.
    """,
    "image_pushes",
])
