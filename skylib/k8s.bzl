# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("//gitops:provider.bzl", "GitopsArtifactsInfo")
load("//push_oci:push_oci.bzl", "push_oci")
load("//skylib:runfile.bzl", "get_runfile_path")
load("//skylib:push_alias.bzl", "pushed_image_alias")
load(
    "//skylib/kustomize:kustomize.bzl",
    "imagePushStatements",
    "kubectl",
    "kustomize",
    kustomize_gitops = "gitops",
)

def _show_impl(ctx):
    script_content = "#!/usr/bin/env bash\nset -e\n"

    kustomize_outputs = []
    script_template = "{template_engine} --template={infile} --variable=NAMESPACE={namespace} --stamp_info_file={info_file}\n"
    for dep in ctx.attr.src.files.to_list():
        kustomize_outputs.append(script_template.format(
            infile = dep.short_path,
            template_engine = ctx.executable._template_engine.short_path,
            namespace = ctx.attr.namespace,
            info_file = ctx.file._info_file.short_path,
        ))

    # ensure kustomize outputs are separated by '---' delimiters
    script_content += "echo '---'\n".join(kustomize_outputs)

    ctx.actions.write(ctx.outputs.executable, script_content, is_executable = True)
    return [
        DefaultInfo(runfiles = ctx.runfiles(files = [ctx.executable._template_engine, ctx.file._info_file] + ctx.files.src)),
    ]

show = rule(
    implementation = _show_impl,
    attrs = {
        "src": attr.label(
            doc = "Input file.",
            mandatory = True,
        ),
        "namespace": attr.string(
            doc = "kubernetes namespace.",
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

        #
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

def k8s_deploy(
        name,  # name of the rule is important for gitops, since it will become a part of the target manifest file name in /cloud
        cluster = "dev",
        user = None,
        namespace = None,
        configmaps_srcs = None,
        secrets_srcs = None,
        configmaps_renaming = None,  # configmaps renaming policy. Could be None or 'hash'.
        manifests = None,
        name_prefix = None,
        name_suffix = None,
        prefix_suffix_app_labels = False,  # apply kustomize configuration to modify "app" labels in Deployments when name prefix or suffix applied
        patches = None,
        image_name_patches = {},
        image_tag_patches = {},
        substitutions = {},  # dict of template parameter substitutions. CLUSTER and NAMESPACE parameters are added automatically.
        configurations = [],  # additional kustomize configuration files. rules_gitops provides
        common_labels = {},  # list of common labels to apply to all objects see commonLabels kustomize docs
        common_annotations = {},  # list of common annotations to apply to all objects see commonAnnotations kustomize docs
        openapi_path = None,  # path to openapi schema file
        deps = [],
        deps_aliases = {},
        images = [],
        image_digest_tag = False,
        image_registry = "docker.io",  # registry to push container to. jenkins will need an access configured for gitops to work. Ignored for mynamespace.
        image_repository = None,  # repository (registry path) to push container to. Generated from the image bazel path if empty.
        objects = [],
        gitops = True,  # make sure to use gitops = False to work with individual namespace. This option will be turned False if namespace is '{BUILD_USER}'
        gitops_path = "cloud",
        app_name = "myapp",
        deployment_branch = None,
        release_branch_prefix = "main",
        start_tag = "{{",
        end_tag = "}}",
        tags = [],  # tags to add to all generated rules.
        visibility = None):
    """ k8s_deploy
    """

    if not manifests:
        manifests = native.glob(["*.yaml", "*.yaml.tpl"])
    if prefix_suffix_app_labels:
        configurations = configurations + [
            "@rules_gitops//skylib/kustomize:nameprefix_deployment_labels_config.yaml",
            "@rules_gitops//skylib/kustomize:namesuffix_deployment_labels_config.yaml",
        ]
    for reservedname in ["CLUSTER", "NAMESPACE"]:
        if substitutions.get(reservedname):
            fail("do not put %s in substitutions parameter of k8s_deploy. It will be added autimatically" % reservedname)
    substitutions = dict(substitutions)
    substitutions["CLUSTER"] = cluster

    # NAMESPACE substitution is deferred until test_setup/kubectl/gitops
    if namespace == "{BUILD_USER}":
        gitops = False

    if not gitops:
        # Mynamespace option
        if not namespace:
            namespace = "{BUILD_USER}"
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
            namespace = namespace,
            configmaps_srcs = configmaps_srcs,
            secrets_srcs = secrets_srcs,
            # disable_name_suffix_hash is renamed to configmaps_renaming in recent Kustomize
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
            objects = objects,
            image_name_patches = image_name_patches,
            image_tag_patches = image_tag_patches,
            openapi_path = openapi_path,
            tags = tags,
            visibility = visibility,
        )
        kubectl(
            name = name + ".apply",
            srcs = [name],
            cluster = cluster,
            user = user,
            namespace = namespace,
            tags = tags,
            visibility = visibility,
        )
        kubectl(
            name = name + ".delete",
            srcs = [name],
            command = "delete",
            cluster = cluster,
            push = False,
            user = user,
            namespace = namespace,
            tags = tags,
            visibility = visibility,
        )
        show(
            name = name + ".show",
            namespace = namespace,
            src = name,
            tags = tags,
            visibility = visibility,
        )
    else:
        # gitops
        if not namespace:
            fail("namespace must be defined for gitops k8s_deploy")
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
            namespace = namespace,
            configmaps_srcs = configmaps_srcs,
            secrets_srcs = secrets_srcs,
            # disable_name_suffix_hash is renamed to configmaps_renaming in recent Kustomize
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
        kubectl(
            name = name + ".apply",
            srcs = [name],
            cluster = cluster,
            user = user,
            namespace = namespace,
            tags = tags,
            visibility = visibility,
        )
        kustomize_gitops(
            name = name + ".gitops",
            srcs = [name],
            cluster = cluster,
            namespace = namespace,
            gitops_path = gitops_path,
            app_name = app_name,
            strip_prefixes = [
                namespace + "-",
                cluster + "-",
            ],
            deployment_branch = deployment_branch,
            release_branch_prefix = release_branch_prefix,
            tags = tags,
            visibility = ["//visibility:public"],
        )
        show(
            name = name + ".show",
            src = name,
            namespace = namespace,
            tags = tags,
            visibility = visibility,
        )

# kubectl template
def _kubectl_config(repository_ctx, args):
    kubectl = repository_ctx.path("kubectl")
    kubeconfig_yaml = repository_ctx.path("kubeconfig")
    exec_result = repository_ctx.execute(
        [kubectl, "--kubeconfig", kubeconfig_yaml, "config"] + args,
        environment = {
            # prevent kubectl config to stumble on shared .kube/config.lock file
            "HOME": str(repository_ctx.path(".")),
        },
        quiet = True,
    )
    if exec_result.return_code != 0:
        fail("Error executing kubectl config %s" % " ".join(args))

def _kubeconfig_impl(repository_ctx):
    """Find local kubernetes certificates"""

    # find and symlink kubectl
    kubectl = repository_ctx.which("kubectl")
    if not kubectl:
        fail("Unable to find kubectl executable. PATH=%s" % repository_ctx.path)
    repository_ctx.symlink(kubectl, "kubectl")
    repository_ctx.file(repository_ctx.path("cluster"), content = repository_ctx.attr.cluster, executable = False)

    # TODO: figure out how to use BUILD_USER
    if "USER" in repository_ctx.os.environ:
        user = repository_ctx.os.environ["USER"]
    else:
        exec_result = repository_ctx.execute(["whoami"])
        if exec_result.return_code != 0:
            fail("Error detecting current user")
        user = exec_result.stdout.rstrip()
    token = None
    ca_crt = None
    kubecert_cert = None
    kubecert_key = None
    server = repository_ctx.attr.server

    # check service account first
    serviceaccount = repository_ctx.path("/var/run/secrets/kubernetes.io/serviceaccount")
    if serviceaccount.exists:
        ca_crt = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        token_file = serviceaccount.get_child("token")
        if token_file.exists:
            exec_result = repository_ctx.execute(["cat", token_file.realpath])
            if exec_result.return_code != 0:
                fail("Error reading user token")
            token = exec_result.stdout.rstrip()

        # use master url from the environemnt
        if "KUBERNETES_SERVICE_HOST" in repository_ctx.os.environ:
            server = "https://%s:%s" % (
                repository_ctx.os.environ["KUBERNETES_SERVICE_HOST"],
                repository_ctx.os.environ["KUBERNETES_SERVICE_PORT"],
            )
        else:
            # fall back to the default
            server = "https://kubernetes.default"
    elif repository_ctx.attr.use_host_config:
        home = repository_ctx.path(repository_ctx.os.environ["HOME"])
        kubeconfig = home.get_child(".kube").get_child("config")
        if repository_ctx.path(kubeconfig).exists:
            repository_ctx.symlink(kubeconfig, repository_ctx.path("kubeconfig"))
        else:
            _kubectl_config(repository_ctx, [
                "set-cluster",
                repository_ctx.attr.cluster,
                "--server",
                server,
            ])
    else:
        home = repository_ctx.path(repository_ctx.os.environ["HOME"])
        certs = home.get_child(".kube").get_child("certs")
        ca_crt = certs.get_child("ca.crt").realpath
        kubecert_cert = certs.get_child("kubecert.cert")
        kubecert_key = certs.get_child("kubecert.key")

    # config set-cluster {cluster} \
    #     --certificate-authority=... \
    #     --server=https://dev3.k8s.tubemogul.info:443 \
    #     --embed-certs",
    if ca_crt:
        _kubectl_config(repository_ctx, [
            "set-cluster",
            repository_ctx.attr.cluster,
            "--server",
            server,
            "--certificate-authority",
            ca_crt,
        ])

    # config set-credentials {user} --token=...",
    if token:
        _kubectl_config(repository_ctx, [
            "set-credentials",
            user,
            "--token",
            token,
        ])

    # config set-credentials {user} --client-certificate=... --embed-certs",
    if kubecert_cert and kubecert_cert.exists:
        _kubectl_config(repository_ctx, [
            "set-credentials",
            user,
            "--client-certificate",
            kubecert_cert.realpath,
        ])

    # config set-credentials {user} --client-key=... --embed-certs",
    if kubecert_key and kubecert_key.exists:
        _kubectl_config(repository_ctx, [
            "set-credentials",
            user,
            "--client-key",
            kubecert_key.realpath,
        ])

    # export repostory contents
    repository_ctx.file("BUILD", """exports_files(["kubeconfig", "kubectl", "cluster"])""", False)

    return {
        "name": repository_ctx.attr.name,
        "cluster": repository_ctx.attr.cluster,
        "server": repository_ctx.attr.server,
        "use_host_config": repository_ctx.attr.use_host_config,
    }

kubeconfig = repository_rule(
    attrs = {
        "cluster": attr.string(),
        "server": attr.string(),
        "use_host_config": attr.bool(),
    },
    environ = [
        "HOME",
        "USER",
        "KUBERNETES_SERVICE_HOST",
        "KUBERNETES_SERVICE_PORT",
    ],
    local = True,
    implementation = _kubeconfig_impl,
)

def _k8s_test_namespace_impl(ctx):
    files = []  # runfiles list

    # add files referenced by rule attributes to runfiles
    files = [ctx.file.kubectl, ctx.file.kubeconfig]

    # create namespace reservation script
    namespace_create = ctx.actions.declare_file(ctx.label.name + ".create")
    ctx.actions.expand_template(
        template = ctx.file._namespace_template,
        substitutions = {
            "%{kubeconfig}": ctx.file.kubeconfig.path,
            "%{kubectl}": ctx.file.kubectl.path,
        },
        output = namespace_create,
        is_executable = True,
    )
    files.append(namespace_create)

    return [DefaultInfo(
        executable = namespace_create,
        runfiles = ctx.runfiles(files = files),
    )]

k8s_test_namespace = rule(
    attrs = {
        "kubeconfig": attr.label(
            allow_single_file = True,
        ),
        "kubectl": attr.label(
            cfg = "exec",
            executable = True,
            allow_single_file = True,
        ),
        "_namespace_template": attr.label(
            default = Label("//skylib:k8s_test_namespace.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    implementation = _k8s_test_namespace_impl,
)

def _k8s_test_setup_impl(ctx):
    kustomize_bin = ctx.toolchains["@rules_gitops//gitops:kustomize_toolchain_type"].kustomizeinfo.bin
    files = []  # runfiles list
    transitive = []
    commands = []  # the list of commands to execute

    # add files referenced by rule attributes to runfiles
    files = [ctx.executable._stamper, ctx.file.kubectl, ctx.file.kubeconfig, kustomize_bin, ctx.executable._it_sidecar, ctx.executable._it_manifest_filter]
    files += ctx.files._set_namespace
    files += ctx.files.cluster

    push_statements, files, pushes_runfiles = imagePushStatements(ctx, [o for o in ctx.attr.objects if GitopsArtifactsInfo in o], files)

    # execute all objects targets
    for obj in ctx.attr.objects:
        if obj.files_to_run.executable:
            # add object' targets and excutables to runfiles
            files.append(obj.files_to_run.executable)
            transitive.append(obj.default_runfiles.files)

            # add object' execution command
            commands.append(get_runfile_path(ctx, obj.files_to_run.executable) + " | ${SET_NAMESPACE} $NAMESPACE | ${IT_MANIFEST_FILTER} | ${KUBECTL} apply -f -")
        else:
            files += obj.files.to_list()
            commands += [ctx.executable._template_engine.short_path + " --template=" + filename.short_path + " --variable=NAMESPACE=${NAMESPACE} | ${SET_NAMESPACE} $NAMESPACE | ${IT_MANIFEST_FILTER} | ${KUBECTL} apply -f -" for filename in obj.files.to_list()]

    files.append(ctx.executable._template_engine)

    sidecar_args = []
    if ctx.attr.setup_timeout:
        sidecar_args.append("-timeout=%s" % ctx.attr.setup_timeout)
    for service in ctx.attr.portforward_services:
        sidecar_args.append("--portforward=%s" % service)
    for app in ctx.attr.wait_for_apps:
        sidecar_args.append("--waitforapp=%s" % app)
    if ctx.attr.allow_errors:
        sidecar_args.append("--allow_errors")
    if ctx.attr.disable_pod_logs:
        sidecar_args.append("--disable_pod_logs")

    # create namespace script
    ctx.actions.expand_template(
        template = ctx.file._namespace_template,
        substitutions = {
            "%{it_sidecar}": ctx.executable._it_sidecar.short_path,
            "%{cluster}": ctx.file.cluster.path,
            "%{kubeconfig}": ctx.file.kubeconfig.path,
            "%{kubectl}": ctx.file.kubectl.path,
            "%{push_statements}": push_statements,
            "%{set_namespace}": ctx.executable._set_namespace.short_path,
            "%{it_manifest_filter}": ctx.executable._it_manifest_filter.short_path,
            "%{statements}": "\n".join(commands),
            "%{sidecar_args}": " ".join(sidecar_args),
        },
        output = ctx.outputs.executable,
    )

    rf = ctx.runfiles(files = files, transitive_files = depset(transitive = transitive))
    rf = rf.merge(ctx.attr._set_namespace[DefaultInfo].default_runfiles)
    for dep_rf in pushes_runfiles:
        rf = rf.merge(dep_rf)
    return [DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = rf,
    )]

k8s_test_setup = rule(
    attrs = {
        "kubeconfig": attr.label(
            #default = Label("@k8s_test//:kubeconfig"),
            allow_single_file = True,
            mandatory = True,
        ),
        "kubectl": attr.label(
            #default = Label("@k8s_test//:kubectl"),
            cfg = "exec",
            executable = True,
            allow_single_file = True,
            mandatory = True,
        ),
        "objects": attr.label_list(
            cfg = "target",
        ),
        "portforward_services": attr.string_list(),
        "setup_timeout": attr.string(default = "10m"),
        "wait_for_apps": attr.string_list(),
        "allow_errors": attr.bool(
            default = False,
            doc = "If true, the test will ignore any kuberntetes errors. Use only in situations when error is a part of the normal workflow, like crashlooping to wait for dependencies.",
        ),
        "disable_pod_logs": attr.bool(
            default = False,
            doc = "If true, the test will not collect logs from pods.",
        ),
        "cluster": attr.label(
            #default = Label("@k8s_test//:cluster"),
            allow_single_file = True,
            mandatory = True,
        ),
        "_it_sidecar": attr.label(
            default = Label("//testing/it_sidecar:it_sidecar"),
            cfg = "exec",
            executable = True,
        ),
        "_namespace_template": attr.label(
            default = Label("//skylib:k8s_test_namespace.sh.tpl"),
            allow_single_file = True,
        ),
        "_set_namespace": attr.label(
            default = Label("//skylib/kustomize:set_namespace"),
            cfg = "exec",
            executable = True,
        ),
        "_it_manifest_filter": attr.label(
            default = Label("//testing/it_manifest_filter:it_manifest_filter"),
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
    executable = True,
    implementation = _k8s_test_setup_impl,
)
