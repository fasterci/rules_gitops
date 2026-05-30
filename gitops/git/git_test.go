package git

import (
	"os"
	oe "os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/fasterci/rules_gitops/gitops/commitmsg"
)

func mustRun(t *testing.T, dir string, name string, args ...string) string {
	cmd := oe.Command(name, args...)
	cmd.Dir = dir
	b, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("failed to execute %s %v: %v\nOutput: %s", name, args, err, string(b))
	}
	return string(b)
}

func createMockRemote(t *testing.T, files map[string]string) string {
	remoteDir, err := os.MkdirTemp("", "mock-remote-*")
	if err != nil {
		t.Fatalf("failed to create temp remote dir: %v", err)
	}

	mustRun(t, remoteDir, "git", "init", "--initial-branch=master")
	mustRun(t, remoteDir, "git", "config", "user.name", "Test User")
	mustRun(t, remoteDir, "git", "config", "user.email", "test@example.com")

	for relPath, content := range files {
		absPath := filepath.Join(remoteDir, relPath)
		if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
			t.Fatalf("failed to create directory: %v", err)
		}
		if err := os.WriteFile(absPath, []byte(content), 0644); err != nil {
			t.Fatalf("failed to write file: %v", err)
		}
	}

	mustRun(t, remoteDir, "git", "add", ".")
	mustRun(t, remoteDir, "git", "commit", "-m", "initial commit")

	return remoteDir
}

func configureGitUser(t *testing.T, dir string) {
	mustRun(t, dir, "git", "config", "user.name", "Test User")
	mustRun(t, dir, "git", "config", "user.email", "test@example.com")
}

func TestClone(t *testing.T) {
	files := map[string]string{
		"cloud/app.yaml": "image: app:v1",
		"readme.md":      "documentation",
	}
	remoteDir := createMockRemote(t, files)
	defer os.RemoveAll(remoteDir)

	// Scenario 1: Clone with sparse checkout restricted to "cloud" directory
	cloneDir1, err := os.MkdirTemp("", "clone-1-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(cloneDir1)

	repo1, err := Clone(remoteDir, cloneDir1, "", "master", "cloud")
	if err != nil {
		t.Fatalf("failed to clone: %v", err)
	}

	if repo1.Dir != cloneDir1 {
		t.Errorf("expected repo dir %s, got %s", cloneDir1, repo1.Dir)
	}

	// Verify app.yaml is checked out
	appYamlPath := filepath.Join(cloneDir1, "cloud/app.yaml")
	if _, err := os.Stat(appYamlPath); os.IsNotExist(err) {
		t.Error("expected cloud/app.yaml to exist in sparse checkout clone")
	}

	// Verify readme.md is not checked out (because it's not in the "cloud" folder)
	readmePath := filepath.Join(cloneDir1, "readme.md")
	if _, err := os.Stat(readmePath); !os.IsNotExist(err) {
		t.Error("expected readme.md not to exist in sparse checkout clone")
	}

	// Scenario 2: Clone with root path (empty string) - should check out all files
	cloneDir2, err := os.MkdirTemp("", "clone-2-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(cloneDir2)

	_, err = Clone(remoteDir, cloneDir2, "", "master", "")
	if err != nil {
		t.Fatalf("failed to clone: %v", err)
	}

	if _, err := os.Stat(filepath.Join(cloneDir2, "cloud/app.yaml")); os.IsNotExist(err) {
		t.Error("expected cloud/app.yaml to exist")
	}
	if _, err := os.Stat(filepath.Join(cloneDir2, "readme.md")); os.IsNotExist(err) {
		t.Error("expected readme.md to exist in full clone")
	}
}

func TestCloneOrCheckout(t *testing.T) {
	files := map[string]string{
		"cloud/app.yaml": "image: app:v1",
	}
	remoteDir := createMockRemote(t, files)
	defer os.RemoveAll(remoteDir)

	localDir, err := os.MkdirTemp("", "clone-or-checkout-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(localDir)

	// Scenario 1: Initial checkout (clean directory)
	_, err = CloneOrCheckout(remoteDir, localDir, "", "master", "cloud", "deploy/")
	if err != nil {
		t.Fatalf("failed to clone or checkout initially: %v", err)
	}

	configureGitUser(t, localDir)

	// Verify files are checked out
	appYamlPath := filepath.Join(localDir, "cloud/app.yaml")
	if _, err := os.Stat(appYamlPath); os.IsNotExist(err) {
		t.Error("expected cloud/app.yaml to exist")
	}

	// Setup local branch and untracked changes
	mustRun(t, localDir, "git", "branch", "deploy/dev")
	err = os.WriteFile(filepath.Join(localDir, "cloud/app.yaml"), []byte("modified locally"), 0644)
	if err != nil {
		t.Fatalf("failed to modify local file: %v", err)
	}

	// Update the remote repository with a new commit
	err = os.WriteFile(filepath.Join(remoteDir, "cloud/app.yaml"), []byte("image: app:v2"), 0644)
	if err != nil {
		t.Fatalf("failed to write remote file: %v", err)
	}
	mustRun(t, remoteDir, "git", "add", ".")
	mustRun(t, remoteDir, "git", "commit", "-m", "remote update")

	// Scenario 2: Existing repository (should clean untracked/modified changes and fetch updates)
	repo2, err := CloneOrCheckout(remoteDir, localDir, "", "master", "cloud", "deploy/")
	if err != nil {
		t.Fatalf("failed to clone or checkout existing: %v", err)
	}

	// Verify local modifications were reset and updates were pulled
	content, err := os.ReadFile(appYamlPath)
	if err != nil {
		t.Fatalf("failed to read file: %v", err)
	}
	if string(content) != "image: app:v2" {
		t.Errorf("expected file content to be updated to 'image: app:v2', got '%s'", string(content))
	}

	// Verify the local branch with prefix "deploy/" was deleted
	branches := mustRun(t, repo2.Dir, "git", "branch")
	if strings.Contains(branches, "deploy/dev") {
		t.Error("expected local branch deploy/dev to be deleted during cleanup")
	}
}

func TestRepoBranchOperationsAndCommit(t *testing.T) {
	files := map[string]string{
		"cloud/app.yaml": "image: app:v1",
	}
	remoteDir := createMockRemote(t, files)
	defer os.RemoveAll(remoteDir)

	localDir, err := os.MkdirTemp("", "repo-ops-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(localDir)

	repo, err := Clone(remoteDir, localDir, "", "master", "cloud")
	if err != nil {
		t.Fatalf("failed to clone: %v", err)
	}
	configureGitUser(t, localDir)

	// Scenario 1: Switch to a new branch
	isNew := repo.SwitchToBranch("deploy/dev", "master")
	if !isNew {
		t.Error("expected SwitchToBranch to return true for a new branch")
	}

	// Scenario 2: Verify it identifies local changes via GetChangedFiles
	err = os.WriteFile(filepath.Join(localDir, "cloud/app.yaml"), []byte("image: app:v1-dev"), 0644)
	if err != nil {
		t.Fatalf("failed to write local file: %v", err)
	}

	changedFiles := repo.GetChangedFiles()
	if len(changedFiles) != 1 || changedFiles[0] != "cloud/app.yaml" {
		t.Errorf("expected changed files to be [cloud/app.yaml], got %v", changedFiles)
	}

	// Scenario 3: Commit and Push
	hasChanges := repo.Commit("commit dev change", "cloud")
	if !hasChanges {
		t.Error("expected Commit to return true when changes are present")
	}

	if !repo.IsClean() {
		t.Error("expected repository to be clean after committing")
	}

	// Try to commit again when clean
	hasChanges2 := repo.Commit("no changes", "cloud")
	if hasChanges2 {
		t.Error("expected Commit to return false when no changes exist")
	}

	// Push the branch
	repo.Push([]string{"deploy/dev"})

	// Scenario 4: Recreate branch (discard and reset to master)
	repo.RecreateBranch("deploy/dev", "master")

	// Verify changes are discarded (reverted back to master state)
	content, err := os.ReadFile(filepath.Join(localDir, "cloud/app.yaml"))
	if err != nil {
		t.Fatalf("failed to read file: %v", err)
	}
	if string(content) != "image: app:v1" {
		t.Errorf("expected branch recreation to reset content to 'image: app:v1', got '%s'", string(content))
	}
}

func TestCloneUpdatePushVerify(t *testing.T) {
	files := map[string]string{
		"cloud/app.yaml": "image: app:v1",
	}
	remoteDir := createMockRemote(t, files)
	defer os.RemoveAll(remoteDir)

	// Clone the repo
	localDir, err := os.MkdirTemp("", "clone-push-local-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(localDir)

	repo, err := Clone(remoteDir, localDir, "", "master", "cloud")
	if err != nil {
		t.Fatalf("failed to clone: %v", err)
	}
	configureGitUser(t, localDir)

	// Create and switch to branch
	isNew := repo.SwitchToBranch("deploy/prod", "master")
	if !isNew {
		t.Error("expected deploy/prod to be a new branch")
	}

	// Update the file in the checked out copy
	updatedContent := "image: app:v2-prod"
	err = os.WriteFile(filepath.Join(localDir, "cloud/app.yaml"), []byte(updatedContent), 0644)
	if err != nil {
		t.Fatalf("failed to write updated file: %v", err)
	}

	// Commit the changes
	hasChanges := repo.Commit("deploy prod change", "cloud")
	if !hasChanges {
		t.Fatal("expected Commit to return true")
	}

	// Push the changes to the remote
	repo.Push([]string{"deploy/prod"})

	// Verify the changes in the remote by cloning to a fresh directory and checking out the branch
	verifyDir, err := os.MkdirTemp("", "clone-push-verify-*")
	if err != nil {
		t.Fatalf("failed to create temp verification dir: %v", err)
	}
	defer os.RemoveAll(verifyDir)

	verifyRepo, err := Clone(remoteDir, verifyDir, "", "deploy/prod", "cloud")
	if err != nil {
		t.Fatalf("failed to clone remote for verification: %v", err)
	}
	_ = verifyRepo // keep reference

	// Read and verify the file content
	content, err := os.ReadFile(filepath.Join(verifyDir, "cloud/app.yaml"))
	if err != nil {
		t.Fatalf("failed to read verified file: %v", err)
	}

	if string(content) != updatedContent {
		t.Errorf("expected pushed content to be '%s', got '%s'", updatedContent, string(content))
	}
}

func TestBranchRecreationOnTargetDeletion(t *testing.T) {
	files := map[string]string{
		"cloud/app.yaml": "image: app:v1",
	}
	remoteDir := createMockRemote(t, files)
	defer os.RemoveAll(remoteDir)

	localDir, err := os.MkdirTemp("", "recreate-push-local-*")
	if err != nil {
		t.Fatalf("failed to create temp clone dir: %v", err)
	}
	defer os.RemoveAll(localDir)

	repo, err := Clone(remoteDir, localDir, "", "master", "cloud")
	if err != nil {
		t.Fatalf("failed to clone: %v", err)
	}
	configureGitUser(t, localDir)

	// Step 1: Switch to a new branch for the release train
	branchName := "deploy/train-a"
	isNew := repo.SwitchToBranch(branchName, "master")
	if !isNew {
		t.Fatal("expected branch to be new")
	}

	// Write mock target outputs
	err = os.WriteFile(filepath.Join(localDir, "cloud/target1.yaml"), []byte("manifest1"), 0644)
	if err != nil {
		t.Fatalf("failed to write target1 file: %v", err)
	}
	err = os.WriteFile(filepath.Join(localDir, "cloud/target2.yaml"), []byte("manifest2"), 0644)
	if err != nil {
		t.Fatalf("failed to write target2 file: %v", err)
	}

	// Commit with commitmsg containing both targets
	targets := []string{"//pkg/a:target1", "//pkg/b:target2"}
	commitMsg := commitmsg.Generate(targets)
	hasChanges := repo.Commit(commitMsg, "cloud")
	if !hasChanges {
		t.Fatal("expected changes to be committed")
	}

	repo.Push([]string{branchName})

	// Step 2: Simulate second run of gitops tool on reused workspace, where target2 has been deleted
	// Switch back to master
	repo.SwitchToBranch("master", "master")

	// Reuse directory - CloneOrCheckout (which does fetch & reset master to remote tracking branch)
	repoReuse, err := CloneOrCheckout(remoteDir, localDir, "", "master", "cloud", "deploy/")
	if err != nil {
		t.Fatalf("failed to checkout: %v", err)
	}
	configureGitUser(t, localDir)

	// Switch to existing branch
	isNew = repoReuse.SwitchToBranch(branchName, "master")
	if isNew {
		t.Fatal("expected branch to already exist")
	}

	// Read last commit message and extract targets
	lastMsg := repoReuse.GetLastCommitMessage()
	oldTargets := commitmsg.ExtractTargets(lastMsg)

	// Verify old targets were extracted correctly
	if len(oldTargets) != 2 || oldTargets[0] != "//pkg/a:target1" || oldTargets[1] != "//pkg/b:target2" {
		t.Errorf("unexpected old targets extracted: %v", oldTargets)
	}

	// Check if target2 is deleted (simulate new list only containing target1)
	newTargets := []string{"//pkg/a:target1"}
	newTargetsMap := make(map[string]bool)
	for _, nt := range newTargets {
		newTargetsMap[nt] = true
	}

	targetDeleted := false
	for _, ot := range oldTargets {
		if !newTargetsMap[ot] {
			targetDeleted = true
			break
		}
	}

	// Since target2 is deleted, recreate the branch to discard old manifests
	if targetDeleted {
		repoReuse.RecreateBranch(branchName, "master")
	}

	// Verify target2.yaml (and target1.yaml from the previous commit) are discarded
	if _, err := os.Stat(filepath.Join(localDir, "cloud/target2.yaml")); !os.IsNotExist(err) {
		t.Error("expected cloud/target2.yaml to be discarded after branch recreation")
	}
	if _, err := os.Stat(filepath.Join(localDir, "cloud/target1.yaml")); !os.IsNotExist(err) {
		t.Error("expected cloud/target1.yaml to be discarded after branch recreation")
	}
}


