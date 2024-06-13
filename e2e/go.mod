module github.com/fasterci/rules_gitops/e2e

go 1.20

require github.com/fasterci/rules_gitops/testing/it_sidecar/client v0.31.8

replace github.com/fasterci/rules_gitops/testing/it_sidecar/client => ../testing/it_sidecar/client
