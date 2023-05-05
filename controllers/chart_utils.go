/*
Copyright 2023.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"os"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/cli"
	"helm.sh/helm/v3/pkg/downloader"
	"helm.sh/helm/v3/pkg/getter"
	"helm.sh/helm/v3/pkg/repo"
)

// LoadChart downloads the Helm chart at the given repository and version.
func LoadChart(repository, chart, version string) (*chart.Chart, error) {
	tmpDir, err := os.MkdirTemp("", "osdk-helm-chart")
	if err != nil {
		return nil, err
	}
	defer func() {
		if err := os.RemoveAll(tmpDir); err != nil {
			ctrlLog.Error(err, "Failed to remove temporary directory")
		}
	}()

	chartPath, err := downloadChart(tmpDir, repository, chart, version)
	if err != nil {
		return nil, err
	}

	return loader.Load(chartPath)
}

func downloadChart(destDir string, repository, chart, version string) (string, error) {
	settings := cli.New()
	getters := getter.All(settings)
	chartURL := ""
	c := downloader.ChartDownloader{
		Out:              os.Stderr,
		Getters:          getters,
		RepositoryConfig: settings.RepositoryConfig,
		RepositoryCache:  settings.RepositoryCache,
	}

	chartURL, err := repo.FindChartInRepoURL(repository, chart, version, "", "", "", getters)
	if err != nil {
		return "", err
	}

	chartArchive, _, err := c.DownloadTo(chartURL, version, destDir)
	if err != nil {
		return "", err
	}

	return chartArchive, nil
}
