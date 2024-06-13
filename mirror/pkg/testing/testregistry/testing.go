package testregistry

import (
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/registry"
)

// SetupRegistry starts a local registry for testing.
//
// If TEST_OCI_REGISTRY is set, it will be used instead.
func SetupRegistry(t *testing.T) (name.Registry, func()) {
	t.Helper()
	if got := os.Getenv("TEST_OCI_REGISTRY"); got != "" {
		reg, err := name.NewRegistry(got)
		if err != nil {
			t.Fatalf("failed to parse TEST_OCI_REGISTRY: %v", err)
		}
		return reg, func() {}
	}
	srv := httptest.NewServer(registry.New())
	t.Logf("Started registry: %s", srv.URL)
	reg, err := name.NewRegistry(strings.TrimPrefix(srv.URL, "http://"))
	if err != nil {
		t.Fatalf("failed to parse test registry: %v", err)
	}
	return reg, srv.Close
}
