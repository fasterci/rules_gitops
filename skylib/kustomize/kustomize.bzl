# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("//gitops:provider.bzl", "AliasInfo", "GitopsArtifactsInfo", "GitopsPushInfo")
load("//skylib:runfile.bzl", "get_runfile_path")
load("//skylib:stamp.bzl", "stamp")

_binaries = {
    "darwin_amd64": ("https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.3/kustomize_v4.5.3_darwin_amd64.tar.gz", "b0a6b0568273d466abd7cd535c556e44aa9ff5f54c07e86ed9f3016b416de992"),
    "linux_amd64": ("https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.3/kustomize_v4.5.3_linux_amd64.tar.gz", "e4dc2f795235b03a2e6b12c3863c44abe81338c5c0054b29baf27dcc734ae693"),
}

def _download_kustomize_impl(ctx):
    if ctx.os.name == "linux":
        platform = "linux_amd64"
    elif ctx.os.name == "mac os x":
        platform = "darwin_amd64"
    else:
        fail("Platform " + ctx.os.name + " is not supported")

    ctx.file("BUILD", """
sh_binary(
    name = "kustomize",
    srcs = ["bin/kustomize"],
    visibility = ["//visibility:public"],
)
""")

    filename, sha256 = _binaries[platform]
    ctx.download_and_extract(filename, "bin/", sha256 = sha256)

download_kustomize = repository_rule(
    _download_kustomize_impl,
)

def kustomize_setup(name):
    download_kustomize(name = name)

def _stamp_file(ctx, infile, output):
    stamps = [ctx.file._info_file]
    stamp_args = [
        "--stamp-info-file=%s" % sf.path
        for sf in stamps
    ]
    ctx.actions.run(
        executable = ctx.executable._stamper,
        arguments = [
            "--format-file=%s" % infile.path,
            "--output=%s" % output.path,
        ] + stamp_args,
        inputs = [infile] + stamps,
        outputs = [output],
        mnemonic = "Stamp",
        tools = [ctx.executable._stamper],
    )

def _is_ignored_src(src):
    basename = src.rsplit("/", 1)[-1]
    return basename.startswith(".")

_script_template = """\
#!/usr/bin/env bash
set -euo pipefail
{kustomize} build --load-restrictor LoadRestrictionsNone --reorder legacy {kustomize_dir} {template_part} {resolver_part} >{out}
"""

def _kustomize_impl(ctx):
    kustomize_bin = ctx.toolchains["@rules_gitops//gitops:kustomize_toolchain_type"].kustomizeinfo.bin
    kustomization_yaml_file = ctx.actions.declare_file(ctx.attr.name + "/kustomization.yaml")
    root = kustomization_yaml_file.dirname

    upupup = "/".join([".."] * (root.count("/") + 1))
    use_stamp = False
    tmpfiles = []
    kustomization_yaml = "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\n"
    kustomization_yaml += "resources:\n"
    for _, f in enumerate(ctx.files.manifests):
        kustomization_yaml += "- {}/{}\n".format(upupup, f.path)

    if ctx.attr.namespace:
        kustomization_yaml += "namespace: '{}'\n".format(ctx.attr.namespace)
        use_stamp = use_stamp or "{" in ctx.attr.namespace

    if ctx.attr.name_prefix:
        kustomization_yaml += "namePrefix: '{}'\n".format(ctx.attr.name_prefix)
        use_stamp = use_stamp or "{" in ctx.attr.name_prefix

    if ctx.attr.name_suffix:
        kustomization_yaml += "nameSuffix: '{}'\n".format(ctx.attr.name_suffix)
        use_stamp = use_stamp or "{" in ctx.attr.name_suffix

    if ctx.attr.configurations:
        kustomization_yaml += "configurations:\n"
        for _, f in enumerate(ctx.files.configurations):
            kustomization_yaml += "- {}/{}\n".format(upupup, f.path)

    if ctx.file.openapi_path:
        kustomization_yaml += "openapi:\n  path: {}/{}\n".format(upupup, ctx.file.openapi_path.path)

    if ctx.files.patches:
        kustomization_yaml += "patches:\n"
        for _, f in enumerate(ctx.files.patches):
            kustomization_yaml += "- {}/{}\n".format(upupup, f.path)

    if ctx.attr.image_name_patches or ctx.attr.image_tag_patches:
        kustomization_yaml += "images:\n"
        for image, new_tag in ctx.attr.image_tag_patches.items():
            new_name = ctx.attr.image_name_patches.get(image, default = None)
            kustomization_yaml += "- name: \"{}\"\n".format(image)
            kustomization_yaml += "  newTag: \"{}\"\n".format(new_tag)
            if new_name != None:
                kustomization_yaml += "  newName: \"{}\"\n".format(new_name)
        for image, new_name in ctx.attr.image_name_patches.items():
            if ctx.attr.image_tag_patches.get(image, default = None) == None:
                kustomization_yaml += "- name: \"{}\"\n".format(image)
                kustomization_yaml += "  newName: \"{}\"\n".format(new_name)

    if ctx.attr.common_labels:
        kustomization_yaml += "commonLabels:\n"
        for k in ctx.attr.common_labels:
            use_stamp = use_stamp or "{" in ctx.attr.common_labels[k]
            kustomization_yaml += "  {}: '{}'\n".format(k, ctx.attr.common_labels[k])

    if ctx.attr.common_annotations:
        kustomization_yaml += "commonAnnotations:\n"
        for k in ctx.attr.common_annotations:
            use_stamp = use_stamp or "{" in ctx.attr.common_annotations[k]
            kustomization_yaml += "  {}: '{}'\n".format(k, ctx.attr.common_annotations[k])

    kustomization_yaml += "generatorOptions:\n"

    kustomization_yaml += "  disableNameSuffixHash: {}\n".format(str(ctx.attr.disable_name_suffix_hash).lower())

    if ctx.attr.configmaps_srcs:
        maps = dict()  # configmap name to list of File objects
        for target in ctx.attr.configmaps_srcs:
            for src in target.files.to_list():
                # ignore dot files
                if _is_ignored_src(src.path):
                    continue
                mapname = src.path.rsplit("/")[-2]
                if not mapname in maps:
                    maps[mapname] = []
                maps[mapname].append(src)
        kustomization_yaml += "configMapGenerator:\n"
        for cmname in maps:
            kustomization_yaml += "- name: {}\n".format(cmname)
            kustomization_yaml += "  files:\n"
            for f in maps[cmname]:
                kustomization_yaml += "  - {}/{}\n".format(upupup, f.path)

    if ctx.attr.secrets_srcs:
        maps = dict()  # secret name to list of File objects
        for target in ctx.attr.secrets_srcs:
            for src in target.files.to_list():
                # ignore dot files
                if _is_ignored_src(src.path):
                    continue
                mapname = src.path.rsplit("/")[-2]
                if not mapname in maps:
                    maps[mapname] = []
                maps[mapname].append(src)
        kustomization_yaml += "secretGenerator:\n"
        for cmname in maps:
            kustomization_yaml += "- name: {}\n".format(cmname)
            kustomization_yaml += "  type: Opaque\n"
            kustomization_yaml += "  files:\n"
            for f in maps[cmname]:
                kustomization_yaml += "  - {}/{}\n".format(upupup, f.path)

    if use_stamp:
        kustomization_yaml_unstamped_file = ctx.actions.declare_file(ctx.attr.name + "/unstamped.yaml")
        ctx.actions.write(kustomization_yaml_unstamped_file, kustomization_yaml)
        _stamp_file(ctx, kustomization_yaml_unstamped_file, kustomization_yaml_file)
    else:
        ctx.actions.write(kustomization_yaml_file, kustomization_yaml)

    transitive_runfiles = []
    resolver_part = ""
    if ctx.attr.images:
        resolver_part += " | {resolver} ".format(resolver = ctx.executable._resolver.path)
        tmpfiles.append(ctx.executable._resolver)
        for img in ctx.attr.images:
            kpi = img[GitopsPushInfo]
            regrepo = kpi.repository
            if "{" in regrepo:
                regrepo = stamp(ctx, regrepo, tmpfiles, ctx.attr.name + regrepo.replace("/", "_"))

            label_str = str(kpi.image_label).lstrip("@")
            resolver_part += " --image {}={}@$(cat {})".format(label_str, regrepo, kpi.digestfile.path)
            tmpfiles.append(kpi.digestfile)
            transitive_runfiles.append(img[DefaultInfo].default_runfiles)
            if AliasInfo in img:
                alias = img[AliasInfo].alias
                resolver_part += " --image {}={}@$(cat {})".format(alias, regrepo, kpi.digestfile.path)

    template_part = ""
    if ctx.attr.substitutions or ctx.attr.deps:
        template_part += "| {} --stamp_info_file={} ".format(ctx.executable._template_engine.path, ctx.file._info_file.path)
        tmpfiles.append(ctx.executable._template_engine)
        tmpfiles.append(ctx.file._info_file)
        for k in ctx.attr.substitutions:
            template_part += "--variable=%s=%s " % (k, ctx.attr.substitutions[k])
        if ctx.attr.start_tag:
            template_part += "--start_tag=%s " % ctx.attr.start_tag
        if ctx.attr.end_tag:
            template_part += "--end_tag=%s " % ctx.attr.end_tag
        d = {
            str(ctx.attr.deps[i].label): ctx.files.deps[i].path
            for i in range(0, len(ctx.attr.deps))
        }
        template_part += " ".join(["--imports=%s=%s" % (k, d[k]) for k in d])
        template_part += " "
        template_part += " ".join([
            "--imports=%s=%s" % (k, d[str(ctx.label.relative(ctx.attr.deps_aliases[k]))])
            for k in ctx.attr.deps_aliases
        ])

        # Image name substitutions
        if ctx.attr.images:
            for _, img in enumerate(ctx.attr.images):
                kpi = img[GitopsPushInfo]
                regrepo = kpi.repository
                if "{" in regrepo:
                    regrepo = stamp(ctx, regrepo, tmpfiles, ctx.attr.name + regrepo.replace("/", "_"))
                label_str = str(kpi.image_label).lstrip("@")
                template_part += " --variable={}={}@$(cat {})".format(label_str, regrepo, kpi.digestfile.path)

                # Image digest
                template_part += " --variable={}=$(cat {} | cut -d ':' -f 2)".format(label_str + ".digest", kpi.digestfile.path)
                template_part += " --variable={}=$(cat {} | cut -c 8-17)".format(label_str + ".short-digest", kpi.digestfile.path)

        template_part += " "

    script = ctx.actions.declare_file("%s-kustomize" % ctx.label.name)
    script_content = _script_template.format(
        kustomize = kustomize_bin.path,
        kustomize_dir = root,
        resolver_part = resolver_part,
        template_part = template_part,
        out = ctx.outputs.yaml.path,
    )
    ctx.actions.write(script, script_content, is_executable = True)

    ctx.actions.run(
        outputs = [ctx.outputs.yaml],
        inputs = ctx.files.manifests + ctx.files.configmaps_srcs + ctx.files.secrets_srcs + ctx.files.configurations + ctx.files.openapi_path + [kustomization_yaml_file] + tmpfiles + ctx.files.patches + ctx.files.deps,
        executable = script,
        mnemonic = "Kustomize",
        tools = [kustomize_bin],
    )

    runfiles = ctx.runfiles(files = ctx.files.deps).merge_all(transitive_runfiles)

    transitive_files = [m[DefaultInfo].files for m in ctx.attr.manifests if GitopsArtifactsInfo in m]
    transitive_files += [obj[DefaultInfo].files for obj in ctx.attr.objects]

    transitive_image_pushes = [m[GitopsArtifactsInfo].image_pushes for m in ctx.attr.manifests if GitopsArtifactsInfo in m]
    transitive_image_pushes += [obj[GitopsArtifactsInfo].image_pushes for obj in ctx.attr.objects]

    return [
        DefaultInfo(
            files = depset(
                [ctx.outputs.yaml],
                transitive = transitive_files,
            ),
            runfiles = runfiles,
        ),
        GitopsArtifactsInfo(
            image_pushes = depset(
                ctx.attr.images,
                transitive = transitive_image_pushes,
            ),
        ),
    ]

kustomize = rule(
    implementation = _kustomize_impl,
    attrs = {
        "configmaps_srcs": attr.label_list(allow_files = True),
        "secrets_srcs": attr.label_list(allow_files = True),
        "deps_aliases": attr.string_dict(default = {}),
        "disable_name_suffix_hash": attr.bool(default = True),
        "end_tag": attr.string(default = "}}"),
        "images": attr.label_list(doc = "a list of images used in manifests", providers = (GitopsPushInfo,)),
        "manifests": attr.label_list(allow_files = True),
        "name_prefix": attr.string(),
        "name_suffix": attr.string(),
        "namespace": attr.string(),
        "objects": attr.label_list(doc = "a list of dependent kustomize objects", providers = (GitopsArtifactsInfo,)),
        "patches": attr.label_list(allow_files = True),
        "image_name_patches": attr.string_dict(default = {}, doc = "set new names for selected images"),
        "image_tag_patches": attr.string_dict(default = {}, doc = "set new tags for selected images"),
        "start_tag": attr.string(default = "{{"),
        "substitutions": attr.string_dict(default = {}),
        "deps": attr.label_list(default = [], allow_files = True),
        "configurations": attr.label_list(allow_files = True),
        "common_labels": attr.string_dict(default = {}),
        "common_annotations": attr.string_dict(default = {}),
        "openapi_path": attr.label(allow_single_file = True, doc = "openapi schema file for the package. Use this attribute to add support for custom resources"),
        "_build_user_value": attr.label(
            default = Label("//skylib:build_user_value.txt"),
            allow_single_file = True,
        ),
        "_info_file": attr.label(
            default = Label("//skylib:more_stable_status.txt"),
            allow_single_file = True,
        ),
        "_resolver": attr.label(
            default = Label("//resolver:resolver"),
            cfg = "exec",
            executable = True,
        ),
        "_stamper": attr.label(
            default = Label("//stamper:stamper"),
            cfg = "exec",
            executable = True,
            allow_files = True,
        ),
        "_template_engine": attr.label(
            default = Label("//templating:fast_template_engine"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_gitops//gitops:kustomize_toolchain_type"],
    outputs = {
        "yaml": "%{name}.yaml",
    },
)

def _push_all_impl(ctx):
    trans_img_pushes = depset(transitive = [obj[GitopsArtifactsInfo].image_pushes for obj in ctx.attr.srcs if obj.files_to_run.executable]).to_list()

    ctx.actions.expand_template(
        template = ctx.file._tpl,
        substitutions = {
            "%{statements}": "\n".join([
                                 "echo pushing {}".format(exe[GitopsPushInfo].repository)
                                 for exe in trans_img_pushes
                             ]) + "\n" +
                             "\n".join([
                                 "async \"%s\"" % get_runfile_path(ctx, exe.files_to_run.executable)
                                 for exe in trans_img_pushes
                             ]) + "\nwaitpids\n",
        },
        output = ctx.outputs.executable,
    )
    runfiles = [obj.files_to_run.executable for obj in trans_img_pushes]
    transitive = depset(transitive = [obj.default_runfiles.files for obj in trans_img_pushes])

    return [
        DefaultInfo(runfiles = ctx.runfiles(files = runfiles, transitive_files = transitive)),
    ]

push_all = rule(
    implementation = _push_all_impl,
    doc = """
push_all run all pushes referred in images attribute
k8s_container_push should be used.
    """,
    attrs = {
        "srcs": attr.label_list(doc = "a list of images used in manifests", providers = (GitopsArtifactsInfo,)),
        "_tpl": attr.label(
            default = Label("//skylib/kustomize:run-all.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
)

def _remove_prefix(s, prefix):
    return s[len(prefix):] if s.startswith(prefix) else s

def _remove_prefixes(s, prefixes):
    for prefix in prefixes:
        s = _remove_prefix(s, prefix)
    return s

def imagePushStatements(
        ctx,
        kustomize_objs,
        files = []):
    statements = ""
    trans_img_pushes = depset(transitive = [obj[GitopsArtifactsInfo].image_pushes for obj in kustomize_objs]).to_list()
    trans_img_pushes = [push for push in trans_img_pushes if push.files_to_run.executable]
    statements += "\n".join([
        "echo  pushing {}".format(exe[GitopsPushInfo].repository if GitopsPushInfo in exe else "")
        for exe in trans_img_pushes
    ]) + "\n"
    statements += "\n".join([
        "async \"%s\"" % get_runfile_path(ctx, exe.files_to_run.executable)
        for exe in trans_img_pushes
    ]) + "\nwaitpids\n"
    files += [obj.files_to_run.executable for obj in trans_img_pushes]
    dep_runfiles = [obj[DefaultInfo].default_runfiles for obj in trans_img_pushes]
    return statements, files, dep_runfiles

def _gitops_impl(ctx):
    cluster = ctx.attr.cluster
    strip_prefixes = ctx.attr.strip_prefixes
    files = []

    push_statements, files, pushes_runfiles = imagePushStatements(ctx, ctx.attr.srcs, files)
    statements = """if [ "$PERFORM_PUSH" == "1" ]; then
{}
fi
    """.format(push_statements)

    namespace = ctx.attr.namespace
    for inattr in ctx.attr.srcs:
        if "{" in namespace:
            fail("unable to gitops namespace with placeholders %s" % inattr.label)  #mynamespace should not be gitopsed
        for infile in inattr.files.to_list():
            statements += ("echo $TARGET_DIR/{gitops_path}/{namespace}/{cluster}/{file}\n" +
                           "mkdir -p $TARGET_DIR/{gitops_path}/{namespace}/{cluster}\n" +
                           "echo '# GENERATED BY {rulename} -> {gitopsrulename}' > $TARGET_DIR/{gitops_path}/{namespace}/{cluster}/{file}\n" +
                           "{template_engine} --template={infile} --variable=NAMESPACE={namespace} --stamp_info_file={info_file} >> $TARGET_DIR/{gitops_path}/{namespace}/{cluster}/{file}\n").format(
                infile = get_runfile_path(ctx, infile),
                rulename = inattr.label,
                gitopsrulename = ctx.label,
                namespace = namespace,
                gitops_path = ctx.attr.gitops_path,
                cluster = cluster,
                file = _remove_prefixes(infile.path.split("/")[-1], strip_prefixes),
                template_engine = get_runfile_path(ctx, ctx.executable._template_engine),
                info_file = get_runfile_path(ctx, ctx.file._info_file),
            )

    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{deployment_branch}": ctx.attr.deployment_branch,
            "%{statements}": statements,
        },
        output = ctx.outputs.executable,
    )
    runfiles = files + ctx.files.srcs + [ctx.executable._template_engine, ctx.file._info_file]
    transitive = depset(transitive = [obj.default_runfiles.files for obj in ctx.attr.srcs])

    rf = ctx.runfiles(files = runfiles, transitive_files = transitive)
    for dep_rf in pushes_runfiles:
        rf = rf.merge(dep_rf)
    return [
        DefaultInfo(runfiles = rf),
        GitopsArtifactsInfo(
            image_pushes = depset(transitive = [obj[GitopsArtifactsInfo].image_pushes for obj in ctx.attr.srcs]),
            deployment_branch = ctx.attr.deployment_branch,
        ),
    ]

gitops = rule(
    attrs = {
        "srcs": attr.label_list(providers = (GitopsArtifactsInfo,)),
        "cluster": attr.string(mandatory = True),
        "namespace": attr.string(mandatory = True),
        "deployment_branch": attr.string(),
        "gitops_path": attr.string(),
        "release_branch_prefix": attr.string(),
        "strip_prefixes": attr.string_list(),
        "_info_file": attr.label(
            default = Label("//skylib:more_stable_status.txt"),
            allow_single_file = True,
        ),
        "_template_engine": attr.label(
            default = Label("//templating:fast_template_engine"),
            executable = True,
            cfg = "exec",
        ),
        "_template": attr.label(
            default = Label("//skylib:k8s_gitops.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    implementation = _gitops_impl,
)

def _kubectl_impl(ctx):
    files = [] + ctx.files.srcs

    statements = ""
    transitive = None
    transitive_runfiles = []

    cluster_arg = ctx.attr.cluster
    cluster_arg = ctx.expand_make_variables("cluster", cluster_arg, {})
    if "{" in ctx.attr.cluster:
        cluster_arg = stamp(ctx, cluster_arg, files, ctx.label.name + ".cluster-name", True)

    if ctx.attr.user:
        user_arg = ctx.attr.user
        user_arg = ctx.expand_make_variables("user", user_arg, {})
        if "{" in ctx.attr.user:
            user_arg = stamp(ctx, user_arg, files, ctx.label.name + ".user-name", True)
    else:
        user_arg = """$(kubectl config view -o jsonpath='{.users[?(@.name == '"\\"${CLUSTER}\\")].name}")"""

    kubectl_command_arg = ctx.attr.command
    kubectl_command_arg = ctx.expand_make_variables("kubectl_command", kubectl_command_arg, {})

    files += [ctx.executable._template_engine, ctx.file._info_file]

    if ctx.attr.push:
        pushes = [obj[GitopsArtifactsInfo].image_pushes for obj in ctx.attr.srcs]
        trans_img_pushes = depset(transitive = pushes).to_list()
        trans_img_pushes = [push for push in trans_img_pushes if push.files_to_run.executable]
        statements += "\n".join([
            "# {}\n".format(exe[GitopsPushInfo].image_label) +
            "echo  pushing {}".format(exe[GitopsPushInfo].repository if GitopsPushInfo in exe else "")
            for exe in trans_img_pushes
        ]) + "\n"
        statements += "\n".join([
            "async \"%s\"" % get_runfile_path(ctx, exe.files_to_run.executable)
            for exe in trans_img_pushes
        ]) + "\nwaitpids\n"
        files += [obj.files_to_run.executable for obj in trans_img_pushes]
        transitive = depset(transitive = [obj.default_runfiles.files for obj in trans_img_pushes])
        transitive_runfiles += [exe[DefaultInfo].default_runfiles for exe in trans_img_pushes]

    namespace = ctx.attr.namespace
    for inattr in ctx.attr.srcs:
        for infile in inattr.files.to_list():
            statements += "{template_engine} --template={infile} --variable=NAMESPACE={namespace} --stamp_info_file={info_file} | kubectl --cluster=\"$CLUSTER\" --user=\"$USER\" {kubectl_command} -f -\n".format(
                infile = infile.short_path,
                kubectl_command = kubectl_command_arg,
                template_engine = get_runfile_path(ctx, ctx.executable._template_engine),
                namespace = namespace,
                info_file = ctx.file._info_file.short_path,
            )

    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{cluster}": cluster_arg,
            "%{user}": user_arg,
            "%{statements}": statements,
        },
        output = ctx.outputs.executable,
    )

    runfiles = ctx.runfiles(files = files, transitive_files = transitive)
    runfiles = runfiles.merge_all(transitive_runfiles)

    return [
        DefaultInfo(runfiles = runfiles),
    ]

kubectl = rule(
    attrs = {
        "srcs": attr.label_list(providers = (GitopsArtifactsInfo,)),
        "cluster": attr.string(mandatory = True),
        "namespace": attr.string(mandatory = True),
        "command": attr.string(default = "apply"),
        "user": attr.string(),
        "push": attr.bool(default = True),
        "_build_user_value": attr.label(
            default = Label("//skylib:build_user_value.txt"),
            allow_single_file = True,
        ),
        "_info_file": attr.label(
            default = Label("//skylib:more_stable_status.txt"),
            allow_single_file = True,
        ),
        "_stamper": attr.label(
            default = Label("//stamper:stamper"),
            cfg = "exec",
            executable = True,
            allow_files = True,
        ),
        "_template": attr.label(
            default = Label("//skylib/kustomize:kubectl.sh.tpl"),
            allow_single_file = True,
        ),
        "_template_engine": attr.label(
            default = Label("//templating:fast_template_engine"),
            executable = True,
            cfg = "exec",
        ),
    },
    executable = True,
    implementation = _kubectl_impl,
)
