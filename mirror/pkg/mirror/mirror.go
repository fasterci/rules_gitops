package mirror

import (
	"context"
	"fmt"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/logs"
	"github.com/google/go-containerregistry/pkg/name"
	v1 "github.com/google/go-containerregistry/pkg/v1"
	"github.com/google/go-containerregistry/pkg/v1/remote"
	"github.com/google/go-containerregistry/pkg/v1/remote/transport"
	"github.com/google/go-containerregistry/pkg/v1/types"
)

func ExecuteContext(ctx context.Context, fromLocation, to, digest string) error {
	fromRef, err := name.ParseReference(fromLocation)
	if err != nil {
		return err
	}
	logs.Debug.Printf("in: %s/%s:%s", fromRef.Context().RegistryStr(), fromRef.Context().RepositoryStr(), fromRef.Identifier())
	dstRef, err := name.ParseReference(to)
	if err != nil {
		return err
	}
	logs.Debug.Print("out:", dstRef)
	hash, err := v1.NewHash(digest)
	if err != nil {
		return err
	}
	ref, err := name.NewDigest(fmt.Sprintf("%s@%s", fromRef.Context(), hash.String()))
	if err != nil {
		return err
	}
	shadst := fmt.Sprintf("%s@%s", dstRef.Context(), hash.String())
	shaDstRef, err := name.NewDigest(shadst)
	if err != nil {
		return err
	}
	// check if dst exists already.
	// We are not verifying if the dst has the same tag
	logs.Progress.Printf("fetching manifest for %s", shaDstRef)
	_, err = remote.Head(shaDstRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err == nil {
		// if the dst manifest exists, check if it's the same as the src
		logs.Progress.Printf("found manifest for %s", shaDstRef)
		return nil
	}

	logs.Progress.Printf("fetching manifest for %s", ref)
	src, err := remote.Get(ref, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
	if err != nil {
		logs.Warn.Printf("unable to fetch source manifest %s: %v", ref, err)
		if e, ok := err.(*transport.Error); ok && e.StatusCode == 404 {
			if _, isTagSrc := fromRef.(name.Tag); isTagSrc {
				// fetch the tag to get the digest
				logs.Progress.Printf("fetching %s", fromRef)
				src2, err := remote.Get(fromRef, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx))
				if err != nil {
					return fmt.Errorf("unable to fetch image %s not found: %v", fromRef, err)
				}
				return fmt.Errorf("source image %s has digest %s", fromRef, src2.Digest)
			}
			return fmt.Errorf("source image %s not found", ref)
		}
		return fmt.Errorf("unable to fetch source manifest %s: %v", ref, err)
	}
	if src.Digest != hash {
		return fmt.Errorf("src digest %s does not match expected %s", src.Digest, hash)
	}
	switch src.MediaType {
	case types.OCIImageIndex, types.DockerManifestList:
		logs.Progress.Printf("fetching index for %s", ref)
		index, err := src.ImageIndex()
		if err != nil {
			return fmt.Errorf("unable to fetch source image index %s: %v", ref, err)
		}
		logs.Progress.Printf("pushing index to %s", dstRef)
		if err := remote.WriteIndex(dstRef, index, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx)); err != nil {
			return err
		}
	case types.OCIManifestSchema1, types.DockerManifestSchema2:
		logs.Progress.Printf("fetching image for %s", ref)
		image, err := src.Image()
		if err != nil {
			return fmt.Errorf("unable to fetch source image %s: %v", ref, err)
		}
		logs.Progress.Printf("pushing image to %s", dstRef)
		if err := remote.Write(dstRef, image, remote.WithAuthFromKeychain(authn.DefaultKeychain), remote.WithContext(ctx)); err != nil {
			return err
		}
	default:
		return fmt.Errorf("unexpected media type for %s: %s", ref, src.MediaType)
	}

	return nil
}
