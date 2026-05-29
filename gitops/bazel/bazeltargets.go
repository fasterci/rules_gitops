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
	"strings"
)

// TargetToExecutable converts bazel target name to respective executable name in bazel-bin
func TargetToExecutable(target string) string {
	if !strings.HasPrefix(target, "//") {
		return target
	}
	t := target[2:]
	var pkg, name string
	idx := strings.Index(t, ":")
	if idx >= 0 {
		pkg = t[:idx]
		name = t[idx+1:]
	} else {
		pkg = t
		lastSlash := strings.LastIndex(pkg, "/")
		if lastSlash >= 0 {
			name = pkg[lastSlash+1:]
		} else {
			name = pkg
		}
	}

	// Candidates in order of preference
	candidates := []string{
		"bazel-bin/" + pkg + "/" + name + "_/" + name,
		"bazel-bin/" + pkg + "/" + name + "_/" + name + ".exe",
		"bazel-bin/" + pkg + "/" + name,
		"bazel-bin/" + pkg + "/" + name + ".exe",
	}

	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}

	// Default fallback (standard layout)
	return "bazel-bin/" + pkg + "/" + name
}

