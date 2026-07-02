def _list_runfiles_impl(ctx):
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join([
            "#!/bin/bash",
            "cd $0.runfiles",
            "find .",
        ]),
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = ctx.files.data)
    transitive_runfiles = []
    for runfiles_attr in (
        # ctx.attr.srcs,
        # ctx.attr.hdrs,
        # ctx.attr.deps,
        ctx.attr.data,
    ):
        for target in runfiles_attr:
            transitive_runfiles.append(target[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge_all(transitive_runfiles)

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            runfiles = runfiles,
            # runfiles = ctx.runfiles(collect_data = False),
        ),
    ]

list_runfiles = rule(
    attrs = {
        "data": attr.label_list(
            allow_files = True,
        ),
    },
    executable = True,
    implementation = _list_runfiles_impl,
)
