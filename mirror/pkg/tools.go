//go:build tools
// +build tools

package pkg

// https://go.dev/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module

import (
	_ "github.com/google/go-containerregistry/cmd/crane"
	_ "github.com/google/go-containerregistry/cmd/registry"
)
