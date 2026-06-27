/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	oe "os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/fasterci/rules_gitops/gitops/commitmsg"
	"github.com/fasterci/rules_gitops/gitops/exec"
	"github.com/fasterci/rules_gitops/gitops/git"
	"github.com/fasterci/rules_gitops/gitops/git/bitbucket"
	"github.com/fasterci/rules_gitops/gitops/git/github"
	"github.com/fasterci/rules_gitops/gitops/git/gitlab"
	"golang.org/x/sync/errgroup"
)

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

// SliceFlags should be used with flags.Var to define a command line flag with multiple values
type SliceFlags []string

func (i *SliceFlags) String() string {
	return "[" + strings.Join(*i, ",") + "]"
}

func (i *SliceFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

var (
	releaseBranch          = flag.String("release_branch", "master", "filter gitops targets by release branch")
	bazelCmd               = flag.String("bazel_cmd", "bazel", "bazel binary to use")
	bazelFlags             SliceFlags
	workspace              = flag.String("workspace", "", "path to workspace root")
	repo                   = flag.String("git_repo", "", "git repo location")
	gitMirror              = flag.String("git_mirror", "", "git mirror location, like /mnt/mirror/bitbucket.tubemogul.info/tm/repo.git for jenkins")
	gitopsPath             = flag.String("gitops_path", "cloud", "location to store files in repo")
	gitopsTmpDir           = flag.String("gitops_tmpdir", os.TempDir(), "location to check out git tree with /cloud.")
	gitopsdir              string
	target                 = flag.String("target", "//... except //experimental/...", "target to scan. Useful for debugging only")
	pushParallelism        = flag.Int("push_parallelism", 1, "Number of image pushes to perform concurrently")
	prInto                 = flag.String("gitops_pr_into", "master", "use this branch as the source branch and target for deployment PR")
	prBody                 = flag.String("gitops_pr_body", "", "a body message for deployment PR")
	prTitle                = flag.String("gitops_pr_title", "", "a title for deployment PR")
	branchName             = flag.String("branch_name", "unknown", "Branch name to use in commit message")
	gitCommit              = flag.String("git_commit", "unknown", "Git commit to use in commit message")
	deployBranchPrefix     = flag.String("deploy_branch_prefix", "deploy/", "prefix to add to all deployment branch names")
	deploymentBranchSuffix = flag.String("deployment_branch_suffix", "", "suffix to add to all deployment branch names")
	gitHost                = flag.String("git_server", "bitbucket", "the git server api to use. 'bitbucket', 'github' or 'gitlab'")
	gitopsKind             SliceFlags
	gitopsRuleName         SliceFlags
	gitopsRuleAttr         SliceFlags
	dryRun                 = flag.Bool("dry_run", false, "Do not create PRs, just print what would be done")
	dryPush                = flag.Bool("dry_push", false, "Do not push, just print what would be done")
	resolvedPushes         SliceFlags
	resolvedBinaries       SliceFlags
	pushRetryMax           = flag.Int("push_retry_max", 2, "maximum number of push retries on race conditions")
)

func init() {
	flag.Var(&bazelFlags, "bazel_flag", "bazel flag to pass during gitops phase. Can be specified multiple times. Default is empty")
	flag.Var(&gitopsKind, "gitops_dependencies_kind", "dependency kind(s) to run during gitops phase. Can be specified multiple times. Default is 'k8s_container_push'")
	flag.Var(&gitopsRuleName, "gitops_dependencies_name", "dependency name(s) to run during gitops phase. Can be specified multiple times. Default is empty")
	flag.Var(&gitopsRuleAttr, "gitops_dependencies_attr", "dependency attribute(s) to run during gitops phase. Use attribute=value format. Can be specified multiple times. Default is empty")
	flag.Var(&resolvedPushes, "resolved_push", "list of resolved push binaries to run. Can be specified multiple times. format is cmd/binary/to/run/command. Default is empty")
	flag.Var(&resolvedBinaries, "resolved_binary", "list of resolved gitops binaries to run. Can be specified multiple times. format is releasetrain:cmd/binary/to/run/command. Default is empty")
	flag.StringVar(&gitopsdir, "gitopsdir", "", "do not use temporary directory for gitops, use this directory instead")
}

type GitopsTarget struct {
	Target           string `json:"target"`
	Binary           string `json:"executable"`
	DeploymentBranch string `json:"deployment_branch"`
}

func cleanTarget(target string) string {
	if strings.HasPrefix(target, "@@//") {
		return target[2:]
	}
	if strings.HasPrefix(target, "@//") {
		return target[1:]
	}
	return target
}

func bazelQueryTargets(query string) []GitopsTarget {
	log.Println("Executing bazel cquery ", query)
	starlarkExpr := `json.encode(struct(deployment_branch = getattr(([providers(target)[p] for p in providers(target) if hasattr(providers(target)[p], 'deployment_branch')] + [None])[0], 'deployment_branch', ''), target = str(target.label), executable = target.files_to_run.executable.path if target.files_to_run.executable else ''))`
	cmd := oe.Command(*bazelCmd, "cquery", "--implicit_deps=false", query, "--output=starlark", "--starlark:expr="+starlarkExpr)
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Fatal(err)
	}
	go func() {
		io.Copy(os.Stderr, stderr)
	}()
	out, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	var targets []GitopsTarget
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		var gt GitopsTarget
		if err := json.Unmarshal([]byte(line), &gt); err != nil {
			log.Fatalf("failed to unmarshal JSON line %q: %v", line, err)
		}
		targets = append(targets, gt)
	}
	return targets
}

func bazelQueryPaths(query string) []string {
	log.Println("Executing bazel cquery ", query)
	cmd := oe.Command(*bazelCmd, "cquery", "--implicit_deps=false", query, "--output=starlark", `--starlark:expr=target.files.to_list()[0].path if target.files.to_list() else ''`)
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Fatal(err)
	}
	go func() {
		io.Copy(os.Stderr, stderr)
	}()
	out, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	var paths []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			paths = append(paths, line)
		}
	}
	return paths
}

func main() {
	flag.Parse()
	if *workspace != "" {
		if err := os.Chdir(*workspace); err != nil {
			log.Fatal(err)
		}
	}
	if len(gitopsKind) == 0 {
		gitopsKind = []string{"k8s_container_push", "push_oci", "push_img"}
	}

	var gitServer git.Server
	switch *gitHost {
	case "github":
		gitServer = git.ServerFunc(github.CreatePR)
	case "gitlab":
		gitServer = git.ServerFunc(gitlab.CreatePR)
	case "bitbucket":
		gitServer = git.ServerFunc(bitbucket.CreatePR)
	default:
		log.Fatalf("unknown vcs host: %s", *gitHost)
	}

	releaseTrains := make(map[string][]GitopsTarget)
	if len(resolvedBinaries) > 0 {
		for _, rb := range resolvedBinaries {
			releaseTrain, bin, found := strings.Cut(rb, ":")
			if !found {
				log.Fatalf("resolved_binaries: invalid resolved_binary format: %s", rb)
			}
			releaseTrains[releaseTrain] = append(releaseTrains[releaseTrain], GitopsTarget{Target: bin, Binary: bin})
		}
	} else {
		q := fmt.Sprintf("attr(deployment_branch, \".+\", attr(release_branch_prefix, \"%s\", kind(gitops, %s)))", *releaseBranch, *target)
		results := bazelQueryTargets(q)
		if *dryRun {
			log.Printf("Found Targets: %v", results)
		}
		for _, t := range results {
			targetName := cleanTarget(t.Target)
			if t.DeploymentBranch != "" {
				releaseTrains[t.DeploymentBranch] = append(releaseTrains[t.DeploymentBranch], GitopsTarget{Target: targetName, Binary: t.Binary, DeploymentBranch: t.DeploymentBranch})
			} else {
				log.Printf("No deployment branch for %s, Skipping", t.Target)
			}
		}
		if (len(releaseTrains)) == 0 {
			log.Println("No matching targets found")
			return
		}
	}

	for train, targets := range releaseTrains {
		fmt.Println(train)
		for _, t := range targets {
			fmt.Println(" ", t.Target)
		}
	}

	if gitopsdir == "" {
		var err error
		gitopsdir, err = os.MkdirTemp(*gitopsTmpDir, "gitops")
		if err != nil {
			log.Fatalf("Unable to create tempdir in %s: %v", *gitopsTmpDir, err)
		}
		defer os.RemoveAll(gitopsdir)
	}
	var updatedGitopsBranches []string
	var pushErr error
	for attempt := 0; attempt <= *pushRetryMax; attempt++ {
		if attempt > 0 {
			log.Printf("Push failed: %v. Retrying checkout, manifest generation, and push (attempt %d/%d)...", pushErr, attempt, *pushRetryMax)
		}
		workdir, err := git.CloneOrCheckout(*repo, gitopsdir, *gitMirror, *prInto, *gitopsPath, *deployBranchPrefix)
		if err != nil {
			log.Fatalf("Unable to clone repo: %v", err)
		}

		var updatedGitopsTargets []string
		updatedGitopsBranches = nil

		for train, targets := range releaseTrains {
			log.Println("train", train)
			branch := fmt.Sprintf("%s%s%s", *deployBranchPrefix, train, *deploymentBranchSuffix)
			newBranch := workdir.SwitchToBranch(branch, *prInto)
			if !newBranch {
				// Find if we need to recreate the branch because target was deleted
				msg := workdir.GetLastCommitMessage()
				targetset := make(map[string]bool)
				for _, t := range targets {
					targetset[t.Target] = true
				}
				oldtargets := commitmsg.ExtractTargets(msg)
				for _, t := range oldtargets {
					if !targetset[t] {
						// target t is not present in a new list
						workdir.RecreateBranch(branch, *prInto)
						break
					}
				}
			}
			var targetNames []string
			for _, target := range targets {
				log.Println("train", train, "target", target.Target)
				exec.Mustex("", target.Binary, "--nopush", "--deployment_root", gitopsdir)
				targetNames = append(targetNames, target.Target)
			}
			if workdir.Commit(fmt.Sprintf("GitOps for release branch %s from %s commit %s\n%s", *releaseBranch, *branchName, *gitCommit, commitmsg.Generate(targetNames)), *gitopsPath) {
				log.Println("branch", branch, "has changes, push is required")
				updatedGitopsTargets = append(updatedGitopsTargets, targetNames...)
				updatedGitopsBranches = append(updatedGitopsBranches, branch)
			}
		}
		if len(updatedGitopsTargets) == 0 {
			log.Println("No gitops changes to push")
			break
		}

		// Push images
		if len(resolvedPushes) > 0 {
			var eg errgroup.Group
			eg.SetLimit(*pushParallelism)
			for _, rp := range resolvedPushes {
				cmd := rp
				eg.Go(func() error {
					exec.Mustex("", cmd)
					return nil
				})
			}
			eg.Wait()
		} else {

			// Create space separated set('//a' '//b' ... '//z') of targets.
			// Target names need to be quoted to protect from + and other special characters
			depsList := "set('" + strings.Join(updatedGitopsTargets, "' '") + "')"
			var qv []string
			for _, kind := range gitopsKind {
				q := fmt.Sprintf("kind(%s, deps(%s))", kind, depsList)
				qv = append(qv, q)
			}
			for _, name := range gitopsRuleName {
				q := fmt.Sprintf("filter(%s, deps(%s))", name, depsList)
				qv = append(qv, q)
			}
			for _, attr := range gitopsRuleAttr {
				name, value, found := strings.Cut(attr, "=")
				if !found {
					value = ".*"
				}
				q := fmt.Sprintf("attr(%s, %s, deps(%s))", name, value, depsList)
				qv = append(qv, q)
			}

			query := strings.Join(qv, " union ")
			paths := bazelQueryPaths(query)
			pathsCh := make(chan string)
			var wg sync.WaitGroup
			wg.Add(*pushParallelism)
			for i := 0; i < *pushParallelism; i++ {
				go func() {
					defer wg.Done()
					for path := range pathsCh {
						executed := false
						absPath, err := filepath.Abs(path)
						if err == nil {
							runfilesDir := absPath + ".runfiles"
							if fi, err := os.Stat(runfilesDir); err == nil && fi.IsDir() {
								workspaceDir := filepath.Join(runfilesDir, "_main")
								if fi, err := os.Stat(workspaceDir); err != nil || !fi.IsDir() {
									workspaceDir = filepath.Join(runfilesDir, "rules_gitops")
								}
								if fi, err := os.Stat(workspaceDir); err == nil && fi.IsDir() {
									log.Printf("Executing %s in %s", absPath, workspaceDir)
									if !*dryPush {
										exec.Mustex(workspaceDir, absPath)
									} else {
										log.Printf("Skipping execution of %s in %s (dry run)", absPath, workspaceDir)
									}
									executed = true
								}
							}
						}
						if !executed {
							fi, err := os.Stat(path)
							if err == nil && fi.Mode().IsRegular() {
								exec.Mustex("", path)
							} else {
								log.Fatalf("push binary path %s is not a regular file, cannot run it", path)
							}
						}
					}
				}()
			}
			for _, p := range paths {
				pathsCh <- p
			}
			close(pathsCh)
			wg.Wait()
		}

		if *dryRun {
			log.Println("dry-run: updated gitops branches: ", updatedGitopsBranches)
			log.Println("dry-run: skipping push")
			break
		} else {
			pushErr = workdir.Push(updatedGitopsBranches)
			if pushErr == nil {
				break
			}
		}
	}
	if pushErr != nil {
		log.Fatalf("Push failed after %d attempts: %v", *pushRetryMax+1, pushErr)
	}

	for _, branch := range updatedGitopsBranches {
		if *dryRun {
			log.Println("dry-run: skipping PR creation: branch", branch, "into", *prInto)
			continue
		}

		title := *prTitle
		if title == "" {
			title = fmt.Sprintf("GitOps deployment %s", branch)
		}

		body := *prBody
		if body == "" {
			body = branch
		}

		if err := gitServer.CreatePR(branch, *prInto, title, body); err != nil {
			log.Fatal("unable to create PR: ", err)
		}
	}
}
