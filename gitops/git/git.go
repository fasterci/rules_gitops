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
package git

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	oe "os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/fasterci/rules_gitops/gitops/exec"
)

var Timeout = flag.Duration("git_timeout", 5*time.Minute, "Timeout for git operations")

// Clone clones a repository. Pass the full repository name, such as
// "https://aleksey.pesternikov@bitbucket.tubemogul.info/scm/tm/repo.git" as the repo.
// Cloned directory will be clean of local changes with primaryBranch branch checked out.
// repo: https://aleksey.pesternikov@bitbucket.tubemogul.info/scm/tm/repo.git
// dir: /tmp/cloudrepo
// mirrorDir: optional (if not empty) local mirror of the repository
func Clone(repo, dir, mirrorDir, primaryBranch, gitopsPath string) (*Repo, error) {
	if err := os.RemoveAll(dir); err != nil {
		return nil, fmt.Errorf("unable to clone repo: %w", err)
	}
	remoteName := "origin"
	args := []string{"clone", "--no-checkout", "--filter=blob:none", "--no-tags", "--origin", remoteName}
	if mirrorDir != "" {
		args = append(args, "--reference", mirrorDir)
	}
	args = append(args, repo, dir)
	exec.MustexWithTimeout(*Timeout, "", "git", args...)
	// Enable sparse-checkout when restricting to a subdir
	if !isRootPath(gitopsPath) {
		exec.MustexWithTimeout(*Timeout, dir, "git", "config", "--local", "core.sparsecheckout", "true")
		genPath := fmt.Sprintf("/*\n!/*/\n/%s/\n", gitopsPath)
		if err := os.WriteFile(filepath.Join(dir, ".git/info/sparse-checkout"), []byte(genPath), 0644); err != nil {
			return nil, fmt.Errorf("unable to create .git/info/sparse-checkout: %w", err)
		}
	}
	exec.MustexWithTimeout(*Timeout, dir, "git", "checkout", primaryBranch)
	ensureUserConfig(dir)

	return &Repo{
		Dir:        dir,
		RemoteName: remoteName,
	}, nil
}

func CloneOrCheckout(repo, dir, mirrorDir, primaryBranch, gitopsPath, branchPrefix string) (r *Repo, err error) {
	newRepo := false
	remoteName := "origin"
	if _, err = os.Stat(dir + "/.git"); os.IsNotExist(err) {
		newRepo = true
		if err = os.MkdirAll(filepath.Dir(dir), os.ModePerm); err != nil && !os.IsExist(err) {
			return nil, err
		}
		args := []string{"clone", "--no-checkout", "--filter=blob:none", "--no-tags", "--origin", remoteName}
		if mirrorDir != "" {
			args = append(args, "--reference", mirrorDir)
		}
		args = append(args, repo, dir)
		exec.MustexWithTimeout(*Timeout, "", "git", args...)
		// Enable sparse-checkout when restricting to a subdir
		if !isRootPath(gitopsPath) {
			exec.MustexWithTimeout(*Timeout, dir, "git", "config", "--local", "core.sparsecheckout", "true")
			genPath := fmt.Sprintf("/*\n!/*/\n/%s/\n", gitopsPath)
			if err := os.WriteFile(filepath.Join(dir, ".git/info/sparse-checkout"), []byte(genPath), 0644); err != nil {
				return nil, fmt.Errorf("unable to create .git/info/sparse-checkout: %w", err)
			}
		}
	} else {
		//existing repo
		exec.MustexWithTimeout(*Timeout, dir, "git", "remote", "set-url", "origin", repo)
		exec.MustexWithTimeout(*Timeout, dir, "git", "reset", "--hard")
	}
	exec.MustexWithTimeout(*Timeout, dir, "git", "checkout", "-f", primaryBranch)
	if !newRepo {
		exec.MustexWithTimeout(*Timeout, dir, "git", "fetch", "origin", "--prune")
		exec.MustexWithTimeout(*Timeout, dir, "git", "reset", "--hard", "origin/"+primaryBranch)
		DeleteLocalBranches(dir, branchPrefix)
	}
	ensureUserConfig(dir)

	return &Repo{
		Dir:        dir,
		RemoteName: remoteName,
	}, nil
}

// DeleteLocalBranches removes local branches by prefix.
func DeleteLocalBranches(dir, branchprefix string) {
	branches := exec.MustexWithTimeout(*Timeout, dir, "git", "for-each-ref", "--format", "%(refname)", "refs/heads/"+branchprefix)
	// returned format:
	// refs/heads/deploy/dev
	// refs/heads/deploy/prod
	// refs/heads/master
	v := strings.Split(branches, "\n")
	for _, line := range v {
		ref := strings.TrimSpace(line)
		if strings.HasPrefix(ref, "refs/heads/"+branchprefix) {
			ref = strings.TrimPrefix(ref, "refs/heads/")
			exec.MustexWithTimeout(*Timeout, dir, "git", "branch", "-D", ref)
		}

	}
}

// Repo is a clone of a git repository. Create with Clone, and don't
// forget to clean it up after.
type Repo struct {
	// Dir is the location of the git repo.
	Dir string
	// RemoteName is the name of the remote that tracks upstream repository.
	RemoteName string
}

// Clean cleans up the repo
func (r *Repo) Clean() error {
	return os.RemoveAll(r.Dir)
}

// Fetch branches from the remote repository based on a specified pattern.
// The branches will be be added to the list tracked remote branches ready to be pushed.
func (r *Repo) Fetch(pattern string) {
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "remote", "set-branches", "--add", r.RemoteName, pattern)
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "fetch", "--force", "--filter=blob:none", "--no-tags", r.RemoteName)
}

// SwitchToBranch switch the repo to specified branch and checkout primaryBranch files over it.
// if branch does not exist it will be created
func (r *Repo) SwitchToBranch(branch, primaryBranch string) (new bool) {
	if _, err := exec.ExWithTimeout(*Timeout, r.Dir, "git", "checkout", branch); err != nil {
		// error checking out, create new
		exec.MustexWithTimeout(*Timeout, r.Dir, "git", "branch", branch, primaryBranch)
		exec.MustexWithTimeout(*Timeout, r.Dir, "git", "checkout", branch)
		return true
	}
	return false
}

// RecreateBranch discards a branch content and reset it from primaryBranch.
func (r *Repo) RecreateBranch(branch, primaryBranch string) {
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "checkout", primaryBranch)
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "branch", "-f", branch, primaryBranch)
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "checkout", branch)
}

// GetLastCommitMessage fetches the commit message from the most recent change of the branch
func (r *Repo) GetLastCommitMessage() (msg string) {
	msg, err := exec.ExWithTimeout(*Timeout, r.Dir, "git", "log", "-1", "--pretty=%B")
	if err != nil {
		return ""
	}
	return msg
}

// Commit all changes to the current branch. returns true if there were any changes
func (r *Repo) Commit(message, gitopsPath string) bool {
	if isRootPath(gitopsPath) {
		exec.MustexWithTimeout(*Timeout, r.Dir, "git", "add", ".")
	} else {
		exec.MustexWithTimeout(*Timeout, r.Dir, "git", "add", gitopsPath)
	}
	if r.IsClean() {
		return false
	}
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "commit", "-a", "-m", message)
	return true
}

// RestoreFile restores the specified file in the repository to its original state
func (r *Repo) RestoreFile(fileName string) {
	exec.MustexWithTimeout(*Timeout, r.Dir, "git", "checkout", "--", fileName)
}

// GetChangedFiles returns a list of files that have been changed in the repository
func (r *Repo) GetChangedFiles() []string {
	s, err := exec.ExWithTimeout(*Timeout, r.Dir, "git", "diff", "--name-only")
	if err != nil {
		log.Fatalf("ERROR: %s", err)
	}
	var files []string
	sc := bufio.NewScanner(strings.NewReader(s))
	for sc.Scan() {
		files = append(files, sc.Text())
	}
	if err := sc.Err(); err != nil {
		log.Fatalf("ERROR: %s", err)
	}
	return files
}

// IsClean returns true if there is no local changes (nothing to commit)
func (r *Repo) IsClean() bool {
	var cmd *oe.Cmd
	if *Timeout > 0 {
		ctx, cancel := context.WithTimeout(context.Background(), *Timeout)
		defer cancel()
		cmd = oe.CommandContext(ctx, "git", "status", "--porcelain")
	} else {
		cmd = oe.Command("git", "status", "--porcelain")
	}
	cmd.Dir = r.Dir
	b, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("ERROR: %s", err)
	}
	return len(b) == 0
}

// Push pushes all local changes to the remote repository
// all changes should be already commited
func (r *Repo) Push(branches []string) error {
	args := append([]string{"push", r.RemoteName, "--force-with-lease", "--set-upstream"}, branches...)
	_, err := exec.ExWithTimeout(*Timeout, r.Dir, "git", args...)
	return err
}

// isRootPath is an internal helper to detect "full repo" case.
func isRootPath(gitopsPath string) bool {
	return gitopsPath == "" || gitopsPath == "."
}

func ensureUserConfig(dir string) {
	if _, err := exec.ExWithTimeout(*Timeout, dir, "git", "config", "--get", "user.name"); err != nil {
		exec.MustexWithTimeout(*Timeout, dir, "git", "config", "--local", "user.name", "Faster CI")
	}
	if _, err := exec.ExWithTimeout(*Timeout, dir, "git", "config", "--get", "user.email"); err != nil {
		exec.MustexWithTimeout(*Timeout, dir, "git", "config", "--local", "user.email", "fasterci@example.com")
	}
}
