# Copyright 2026 The rules_gitops Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("//gitops:provider.bzl", "GitopsArtifactsInfo", "GitopsPushInfo")
load("//push_oci:push_oci.bzl", "push_oci")
load("//skylib:push_alias.bzl", "pushed_image_alias")
load("//skylib:runfile.bzl", "get_runfile_path")
load("//skylib:stamp.bzl", "stamp")
load(
    "//skylib/kustomize:kustomize.bzl",
    "imagePushStatements",
    "kustomize",
)

def _image_pushes(name_suffix, images, image_registry, image_repository, image_digest_tag, tags = []):
    image_pushes = []

    def process_image(image_label, image_alias = None):
        rule_name_parts = [image_label, image_registry, image_repository]
        rule_name_parts = [p for p in rule_name_parts if p]
        rule_name = "_".join(rule_name_parts)
        rule_name = rule_name.replace("/", "_").replace(":", "_").replace("@", "_").replace(".", "_")
        rule_name = rule_name.strip("_")
        if not native.existing_rule(rule_name + name_suffix):
            push_oci(
                name = rule_name + name_suffix,
                image = image_label,  # buildifier: disable=uninitialized
                image_digest_tag = image_digest_tag,
                registry = image_registry,
                repository = image_repository,
                tags = tags,
                visibility = ["//visibility:public"],
            )
        if not image_alias:
            return rule_name + name_suffix

        if not native.existing_rule(rule_name + "_alias_" + name_suffix):
            pushed_image_alias(
                name = rule_name + "_alias_" + name_suffix,
                alias = image_alias,
                pushed_image = rule_name + name_suffix,
                tags = tags,
                visibility = ["//visibility:public"],
            )
        return rule_name + "_alias_" + name_suffix

    if type(images) == "dict":
        for image_alias in images:
            image = images[image_alias]
            push = process_image(image, image_alias)
            image_pushes.append(push)
    else:
        for image in images:
            push = process_image(image)
            image_pushes.append(push)
    return image_pushes

def _gcloud_run_impl(ctx):
    files = [] + ctx.files.srcs
    yq_bin = ctx.toolchains["@yq.bzl//yq/toolchain:type"].yqinfo.bin
    files.append(yq_bin)
    statements = ""
    transitive = None
    transitive_runfiles = []

    project = ctx.attr.project
    if "{" in ctx.attr.project:
        project = stamp(ctx, project, files, ctx.label.name + ".project-name", True)

    region = ctx.attr.region
    if "{" in ctx.attr.region:
        region = stamp(ctx, region, files, ctx.label.name + ".region-name", True)

    command = ctx.attr.command
    push = ctx.attr.push

    files += [ctx.executable._template_engine, ctx.file._info_file]

    if push:
        pushes = [obj[GitopsArtifactsInfo].image_pushes for obj in ctx.attr.srcs]
        trans_img_pushes = depset(transitive = pushes).to_list()
        trans_img_pushes = [push for push in trans_img_pushes if push.files_to_run.executable]
        statements += "\n".join([
            "# {}\n".format(exe[GitopsPushInfo].image_label) +
            "echo pushing {}".format(exe[GitopsPushInfo].repository if GitopsPushInfo in exe else "")
            for exe in trans_img_pushes
        ]) + "\n"
        statements += "\n".join([
            "async \"%s\"" % get_runfile_path(ctx, exe.files_to_run.executable)
            for exe in trans_img_pushes
        ]) + "\nwaitpids\n"
        files += [obj.files_to_run.executable for obj in trans_img_pushes]
        transitive = depset(transitive = [obj.default_runfiles.files for obj in trans_img_pushes])
        transitive_runfiles += [exe[DefaultInfo].default_runfiles for exe in trans_img_pushes]

    for inattr in ctx.attr.srcs:
        for infile in inattr.files.to_list():
            if command == "replace":
                statements += "{template_engine} --template={infile} --variable=PROJECT=\"$PROJECT\" --variable=REGION=\"$REGION\" --stamp_info_file={info_file} | gcloud run services replace - --project=\"$PROJECT\" --region=\"$REGION\"\n".format(
                    infile = get_runfile_path(ctx, infile),
                    template_engine = get_runfile_path(ctx, ctx.executable._template_engine),
                    info_file = get_runfile_path(ctx, ctx.file._info_file),
                )
            elif command == "delete":
                statements += ("SERVICE=$({yq_bin_path} '.metadata.name' {infile})\n" +
                               "if [ -z \"$SERVICE\" ] || [ \"$SERVICE\" = \"null\" ]; then\n" +
                               "  echo \"Error: Failed to extract service name from manifest {infile}\" >&2\n" +
                               "  exit 1\n" +
                               "fi\n" +
                               "gcloud run services delete \"$SERVICE\" --project=\"$PROJECT\" --region=\"$REGION\"\n").format(
                    yq_bin_path = get_runfile_path(ctx, yq_bin),
                    infile = get_runfile_path(ctx, infile),
                )
            else:
                fail("Unsupported command: %s" % command)

    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{project}": project,
            "%{region}": region,
            "%{statements}": statements,
        },
        output = ctx.outputs.executable,
    )

    runfiles = ctx.runfiles(files = files, transitive_files = transitive)
    runfiles = runfiles.merge_all(transitive_runfiles)

    return [
        DefaultInfo(runfiles = runfiles),
    ]

gcloud_run = rule(
    attrs = {
        "srcs": attr.label_list(providers = (GitopsArtifactsInfo,)),
        "project": attr.string(mandatory = True),
        "region": attr.string(mandatory = True),
        "command": attr.string(default = "replace"),
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
            default = Label("//gitops:cloudrun.sh.tpl"),
            allow_single_file = True,
        ),
        "_template_engine": attr.label(
            default = Label("//templating:fast_template_engine"),
            executable = True,
            cfg = "exec",
        ),
    },
    executable = True,
    implementation = _gcloud_run_impl,
    toolchains = ["@yq.bzl//yq/toolchain:type"],
)

def _remove_prefix(s, prefix):
    return s[len(prefix):] if s.startswith(prefix) else s

def _remove_prefixes(s, prefixes):
    for prefix in prefixes:
        s = _remove_prefix(s, prefix)
    return s

def _cloudrun_gitops_impl(ctx):
    region = ctx.attr.region
    project = ctx.attr.project
    strip_prefixes = ctx.attr.strip_prefixes
    files = []

    push_statements, files, pushes_runfiles = imagePushStatements(ctx, ctx.attr.srcs, files)
    statements = """if [ "$PERFORM_PUSH" == "1" ]; then
{}
fi
    """.format(push_statements)

    if "{" in region:
        fail("unable to gitops region with placeholders %s" % region)
    if "{" in project:
        fail("unable to gitops project with placeholders %s" % project)

    for inattr in ctx.attr.srcs:
        for infile in inattr.files.to_list():
            statements += ("echo $TARGET_DIR/{gitops_path}/{project}/{region}/{file}\n" +
                           "mkdir -p $TARGET_DIR/{gitops_path}/{project}/{region}\n" +
                           "echo '# GENERATED BY {rulename} -> {gitopsrulename}' > $TARGET_DIR/{gitops_path}/{project}/{region}/{file}\n" +
                           "{template_engine} --template={infile} --variable=PROJECT={project} --variable=REGION={region} --stamp_info_file={info_file} >> $TARGET_DIR/{gitops_path}/{project}/{region}/{file}\n").format(
                infile = get_runfile_path(ctx, infile),
                rulename = inattr.label,
                gitopsrulename = ctx.label,
                project = project,
                gitops_path = ctx.attr.gitops_path,
                region = region,
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

cloudrun_gitops = rule(
    attrs = {
        "srcs": attr.label_list(providers = (GitopsArtifactsInfo,)),
        "project": attr.string(mandatory = True),
        "region": attr.string(mandatory = True),
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
    implementation = _cloudrun_gitops_impl,
)

def _cloudrun_show_impl(ctx):
    script_content = """#!/usr/bin/env bash
set -e

function guess_runfiles() {
    if [ -d "${BASH_SOURCE[0]}.runfiles" ]; then
        # Runfiles are adjacent to the current script.
        echo "$( cd "${BASH_SOURCE[0]}.runfiles" && pwd )"
    else
        # The current script is within some other script's runfiles.
        mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        echo $mydir | sed -e 's|\\(.*\\.runfiles\\)/.*|\\1|'
    fi
}

RUNFILES=${RUNFILES:-$(guess_runfiles)}
"""

    outputs = []
    script_template = "{template_engine} --template={infile} --variable=PROJECT={project} --variable=REGION={region} --stamp_info_file={info_file}\n"
    for dep in ctx.attr.src.files.to_list():
        outputs.append(script_template.format(
            infile = get_runfile_path(ctx, dep),
            template_engine = get_runfile_path(ctx, ctx.executable._template_engine),
            project = ctx.attr.project,
            region = ctx.attr.region,
            info_file = get_runfile_path(ctx, ctx.file._info_file),
        ))

    script_content += "echo '---'\n".join(outputs)

    ctx.actions.write(ctx.outputs.executable, script_content, is_executable = True)
    return [
        DefaultInfo(runfiles = ctx.runfiles(files = [ctx.executable._template_engine, ctx.file._info_file] + ctx.files.src)),
    ]

cloudrun_show = rule(
    implementation = _cloudrun_show_impl,
    attrs = {
        "src": attr.label(
            doc = "Input file.",
            mandatory = True,
        ),
        "project": attr.string(
            mandatory = True,
        ),
        "region": attr.string(
            mandatory = True,
        ),
        "_info_file": attr.label(
            default = Label("//skylib:more_stable_status.txt"),
            allow_single_file = True,
        ),
        "_template_engine": attr.label(
            default = Label("//templating:fast_template_engine"),
            executable = True,
            cfg = "exec",
        ),
    },
    executable = True,
)

def cloudrun_deploy(
        name,
        project = None,
        region = None,
        configmaps_srcs = None,
        secrets_srcs = None,
        configmaps_renaming = None,
        manifests = None,
        name_prefix = None,
        name_suffix = None,
        patches = None,
        image_name_patches = {},
        image_tag_patches = {},
        substitutions = {},
        configurations = [],
        common_labels = {},
        common_annotations = {},
        openapi_path = "@rules_gitops//skylib:run_schema.json",
        deps = [],
        deps_aliases = {},
        images = [],
        image_digest_tag = False,
        image_registry = "gcr.io",
        image_repository = None,
        gitops = True,
        gitops_path = "cloud",
        deployment_branch = None,
        release_branch_prefix = "main",
        start_tag = "{{",
        end_tag = "}}",
        tags = [],
        visibility = None):
    if not manifests:
        manifests = native.glob(["*.yaml", "*.yaml.tpl"])

    for reservedname in ["PROJECT", "REGION"]:
        if substitutions.get(reservedname):
            fail("do not put %s in substitutions parameter of cloudrun_deploy. It will be added autimatically" % reservedname)
    substitutions = dict(substitutions)
    substitutions["PROJECT"] = project
    substitutions["REGION"] = region

    if not gitops:
        image_pushes = _image_pushes(
            name_suffix = "-mynamespace.push",
            images = images,
            image_registry = image_registry + "/mynamespace",
            image_repository = image_repository,
            image_digest_tag = image_digest_tag,
            tags = tags,
        )
        kustomize(
            name = name,
            namespace = project,
            configmaps_srcs = configmaps_srcs,
            secrets_srcs = secrets_srcs,
            disable_name_suffix_hash = (configmaps_renaming != "hash"),
            images = image_pushes,
            manifests = manifests,
            substitutions = substitutions,
            deps = deps,
            deps_aliases = deps_aliases,
            start_tag = start_tag,
            end_tag = end_tag,
            name_prefix = name_prefix,
            name_suffix = name_suffix,
            configurations = configurations,
            common_labels = common_labels,
            common_annotations = common_annotations,
            patches = patches,
            image_name_patches = image_name_patches,
            image_tag_patches = image_tag_patches,
            openapi_path = openapi_path,
            tags = tags,
            visibility = visibility,
        )
        gcloud_run(
            name = name + ".apply",
            srcs = [name],
            project = project,
            region = region,
            command = "replace",
            tags = tags,
            visibility = visibility,
        )
        gcloud_run(
            name = name + ".delete",
            srcs = [name],
            command = "delete",
            project = project,
            region = region,
            push = False,
            tags = tags,
            visibility = visibility,
        )
        cloudrun_show(
            name = name + ".show",
            src = name,
            project = project,
            region = region,
            tags = tags,
            visibility = visibility,
        )
    else:
        if not region:
            fail("region must be defined for gitops cloudrun_deploy")
        if not project:
            fail("project must be defined for gitops cloudrun_deploy")

        image_pushes = _image_pushes(
            name_suffix = ".push",
            images = images,
            image_registry = image_registry,
            image_repository = image_repository,
            image_digest_tag = image_digest_tag,
            tags = tags,
        )
        kustomize(
            name = name,
            namespace = project,
            configmaps_srcs = configmaps_srcs,
            secrets_srcs = secrets_srcs,
            disable_name_suffix_hash = (configmaps_renaming != "hash"),
            images = image_pushes,
            manifests = manifests,
            visibility = visibility,
            substitutions = substitutions,
            deps = deps,
            deps_aliases = deps_aliases,
            start_tag = start_tag,
            end_tag = end_tag,
            name_prefix = name_prefix,
            name_suffix = name_suffix,
            configurations = configurations,
            common_labels = common_labels,
            common_annotations = common_annotations,
            patches = patches,
            image_name_patches = image_name_patches,
            image_tag_patches = image_tag_patches,
            openapi_path = openapi_path,
            tags = tags,
        )
        gcloud_run(
            name = name + ".apply",
            srcs = [name],
            project = project,
            region = region,
            command = "replace",
            tags = tags,
            visibility = visibility,
        )
        gcloud_run(
            name = name + ".delete",
            srcs = [name],
            command = "delete",
            project = project,
            region = region,
            push = False,
            tags = tags,
            visibility = visibility,
        )
        cloudrun_gitops(
            name = name + ".gitops",
            srcs = [name],
            project = project,
            region = region,
            gitops_path = gitops_path,
            strip_prefixes = [
                project + "-",
                region + "-",
            ],
            deployment_branch = deployment_branch,
            release_branch_prefix = release_branch_prefix,
            tags = tags,
            visibility = ["//visibility:public"],
        )
        cloudrun_show(
            name = name + ".show",
            src = name,
            project = project,
            region = region,
            tags = tags,
            visibility = visibility,
        )
