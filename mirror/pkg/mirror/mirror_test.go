package mirror_test

import (
	"context"
	"log"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/fasterci/rules_gitops/mirror/pkg/mirror"
	"github.com/fasterci/rules_gitops/mirror/pkg/testing/testregistry"
	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/registry"
	"github.com/google/go-containerregistry/pkg/v1/random"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

var (
	fromRegistry     name.Registry
	fromImg, fromIdx string
	digest1, digest2 string
	idxDigest        string
)

func must[T any](t T, err error) T {
	if err != nil {
		panic(err)
	}
	return t
}

func TestMain(m *testing.M) {
	srv := httptest.NewServer(registry.New())
	reg, err := name.NewRegistry(strings.TrimPrefix(srv.URL, "http://"))
	if err != nil {
		log.Fatalf("failed to parse test registry: %v", err)
	}
	defer srv.Close()
	fromRegistry = reg

	img1 := must(random.Image(1024, 1))
	img2 := must(random.Image(1024, 1))
	fromImg = reg.Name() + "/some/thing:tag"
	fromRef := must(name.ParseReference(fromImg))
	err = remote.Write(fromRef, img1, remote.WithAuthFromKeychain(authn.DefaultKeychain))
	if err != nil {
		log.Fatalf("failed to write image %s: %v", fromImg, err)
	}
	err = remote.Write(fromRef, img2, remote.WithAuthFromKeychain(authn.DefaultKeychain))
	if err != nil {
		log.Fatalf("failed to write image %s: %v", fromImg, err)
	}
	digest1 = must(img1.Digest()).String()
	digest2 = must(img2.Digest()).String()

	idx1 := must(random.Index(1024, 1, 2))
	fromIdx = reg.Name() + "/some/index/thing:tag"
	err = remote.WriteIndex(must(name.ParseReference(fromIdx)), idx1, remote.WithAuthFromKeychain(authn.DefaultKeychain))
	if err != nil {
		log.Fatalf("failed to write index %s: %v", fromIdx, err)
	}
	idxDigest = must(idx1.Digest()).String()

	os.Exit(m.Run())
}

func TestExecuteContext_HappypathTag(t *testing.T) {
	r, cleanup := testregistry.SetupRegistry(t)
	defer cleanup()

	from := fromImg
	// note: this hash is not the very recent one, but it's valid actual hash of some previous version
	hash := digest1
	to := r.Name() + "/distroless/base:nonroot-amd64"

	ctx := context.Background()
	if d, ok := t.Deadline(); ok {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, d)
		defer cancel()
	}

	err := mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}

	dstRef, err := name.ParseReference(to)
	if err != nil {
		t.Fatalf("Failed to parse reference %s: %v", to, err)
	}
	r1, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r1.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r1.Digest)
	}

	err = mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}
	r2, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r2.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r2.Digest)
	}

}

func TestExecuteContext_UpgradeTag(t *testing.T) {
	r, cleanup := testregistry.SetupRegistry(t)
	defer cleanup()

	from := fromImg
	hash := digest1
	to := r.Name() + "/distroless/base:nonroot-amd64"

	ctx := context.Background()
	if d, ok := t.Deadline(); ok {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, d)
		defer cancel()
	}

	err := mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}

	dstRef, err := name.ParseReference(to)
	if err != nil {
		t.Fatalf("Failed to parse reference %s: %v", to, err)
	}
	r1, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r1.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r1.Digest)
	}

	hash2 := digest2

	err = mirror.ExecuteContext(ctx, from, to, hash2)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}
	r2, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r2.Digest.String() != hash2 {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash2, r2.Digest)
	}

}

func TestExecuteContext_HappypathSha(t *testing.T) {
	r, cleanup := testregistry.SetupRegistry(t)
	defer cleanup()

	from := fromRegistry.Name() + "/some/thing@" + digest1
	hash := digest1
	to := r.Name() + "/distroless/base@" + digest1

	ctx := context.Background()
	if d, ok := t.Deadline(); ok {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, d)
		defer cancel()
	}

	err := mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}

	dstRef, err := name.ParseReference(to)
	if err != nil {
		t.Fatalf("Failed to parse reference %s: %v", to, err)
	}
	r1, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r1.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r1.Digest)
	}

	err = mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}
	r2, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r2.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r2.Digest)
	}

}

func TestExecuteContext_HappypathIndexSha(t *testing.T) {
	r, cleanup := testregistry.SetupRegistry(t)
	defer cleanup()

	from := fromIdx
	hash := idxDigest
	to := r.Name() + "/dest/multiplatform"

	ctx := context.Background()
	if d, ok := t.Deadline(); ok {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, d)
		defer cancel()
	}

	err := mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}

	dstRef, err := name.ParseReference(to)
	if err != nil {
		t.Fatalf("Failed to parse reference %s: %v", to, err)
	}
	r1, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r1.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r1.Digest)
	}

	err = mirror.ExecuteContext(ctx, from, to, hash)
	if err != nil {
		t.Fatalf("Failed to mirror %s to %s: %v", from, to, err)
	}
	r2, err := remote.Get(dstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		t.Fatalf("Failed to fetch %s: %v", to, err)
	}
	if r2.Digest.String() != hash {
		t.Fatalf("Expected %s to have digest %s, got %s", to, hash, r2.Digest)
	}

}

func TestExecuteContext_BadSha(t *testing.T) {
	r, cleanup := testregistry.SetupRegistry(t)
	defer cleanup()

	// from := "gcr.io/distroless/base:nonroot-amd64"
	from := fromImg
	// note: this hash is incorrect
	hash := "sha256:1c9093af306ef03503b8450b08fe6a2a13ba6d2c697ff74031a915f9201f6434"
	to := r.Name() + "/distroless/base:nonroot-amd64"

	ctx := context.Background()
	if d, ok := t.Deadline(); ok {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, d)
		defer cancel()
	}

	err := mirror.ExecuteContext(ctx, from, to, hash)
	if err == nil {
		t.Fatalf("error expected")
	}
	if !strings.Contains(err.Error(), " has digest sha256:") {
		t.Fatalf("unexpected error %v", err)
	}

}
