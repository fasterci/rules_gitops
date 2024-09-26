package github

import (
	"context"
	"errors"
	"flag"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v58/github"
)

var (
	git                     = "git"
	repoOwner               = flag.String("github_repo_owner", "", "the owner user/organization to use for github api requests")
	repo                    = flag.String("github_repo", "", "the repo to use for github api requests")
	githubEnterpriseHost    = flag.String("github_enterprise_host", "", "The host name of the private enterprise github, e.g. git.corp.adobe.com")
	message                 = flag.String("message", "", "Message to send")
	privateKey              = flag.String("private_key", "/var/run/agent-secrets/buildkite-agent/secrets/github-pr-creator-key", "Private Key")
	gitHubAppId             = flag.Int64("github_app_id", 257131, "GitHub App Id")
	gitHubAppInstallationId = flag.Int64("github_installation_id", 30831292, "GitHub App Id")
	gitHubUser              = flag.String("github_user", "etsy", "GitHub User")
	gitHubAppName           = flag.String("github_app_name", "", "Name of the GitHub App")
)

func CreatePR(from, to, title, body string) error {
	if *repoOwner == "" {
		return errors.New("github_repo_owner must be set")
	}
	if *repo == "" {
		return errors.New("github_repo must be set")
	}

	ctx := context.Background()

	// get an installation token request handler for the github app
	itr, err := ghinstallation.NewKeyFromFile(http.DefaultTransport, *gitHubAppId, *gitHubAppInstallationId, *privateKey)
	if err != nil {
		log.Println("failed reading key", "key", *privateKey, "err", err)
		return err
	}

	var gh *github.Client
	if *githubEnterpriseHost != "" {
		baseUrl := "https://" + *githubEnterpriseHost + "/api/v3/"
		uploadUrl := "https://" + *githubEnterpriseHost + "/api/uploads/"
		var err error
		gh, err = github.NewEnterpriseClient(baseUrl, uploadUrl, &http.Client{Transport: itr})
		if err != nil {
			log.Println("Error in creating github client", err)
			return nil
		}
	} else {
		gh = github.NewClient(&http.Client{Transport: itr})
	}

	pr := &github.NewPullRequest{
		Title:               &title,
		Head:                &from,
		Base:                &to,
		Body:                &body,
		Issue:               nil,
		MaintainerCanModify: new(bool),
		Draft:               new(bool),
	}
	createdPr, resp, err := gh.PullRequests.Create(ctx, *repoOwner, *repo, pr)
	if err == nil {
		log.Println("Created PR: ", *createdPr.URL)
		return err
	}

	if resp.StatusCode == http.StatusUnprocessableEntity {
		// Handle the case: "Create PR" request fails because it already exists
		log.Println("Reusing existing PR")
		return nil
	}

	// All other github responses
	defer resp.Body.Close()
	responseBody, readingErr := ioutil.ReadAll(resp.Body)
	if readingErr != nil {
		log.Println("cannot read response body")
	} else {
		log.Println("github response: ", string(responseBody))
	}

	return err
}
