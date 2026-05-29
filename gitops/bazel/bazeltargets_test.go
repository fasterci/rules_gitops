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
package bazel

import (
	"os"
	"testing"
)

func TestTargetToExecutableHappypath(t *testing.T) {
	s := TargetToExecutable("//rtb/bidder:rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops")
	if s != "bazel-bin/rtb/bidder/rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops" {
		t.Error("unexpected result", s)
	}
}

func TestTargetToExecutableGoLayout(t *testing.T) {
	// Create a dummy file to simulate the go binary in bazel-bin
	dir := "bazel-bin/rtb/bidder/rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops_"
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll("bazel-bin")

	filePath := dir + "/rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops"
	err = os.WriteFile(filePath, []byte("dummy"), 0644)
	if err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	s := TargetToExecutable("//rtb/bidder:rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops")
	expected := "bazel-bin/rtb/bidder/rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops_/rtb-uat-k8s01-iad-1b-bidder-first-uat.gitops"
	if s != expected {
		t.Errorf("expected %s, got %s", expected, s)
	}
}

