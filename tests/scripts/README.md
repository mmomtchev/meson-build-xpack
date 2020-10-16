# Scripts to test the meson-build binaries

The testing procedure of the meson-build binaries is a bit special, since it
does not test the content of the GitHub repository, but the binary archives.

As such the test is not triggered by GitHub commits but manually, by running
various scripts.

The location of the binaries can be either the final release or one of
the pre-release locations:

- https://github.com/xpack-dev-tools/meson-build-xpack/releases
- https://github.com/xpack-dev-tools/pre-releases/releases

## GitHub repo

The test scripts are part of the `meson-build` xPack:

```bash
rm -rf ~/Downloads/meson-build-xpack.git; \
git clone --recurse-submodules -b xpack-develop \
  https://github.com/xpack-dev-tools/meson-build-xpack.git \
  ~/Downloads/meson-build-xpack.git
```

The scripts are in the `tests/scripts` folder, and there is also a
common script in `helper/scripts/test-functions-source.sh`.

## Enable Travis

To enable the travis tests:

- login to https://travis-ci.org/ with the GitHub credentials
- in the user settings, select the **3rd Party xpack Dev Tools** organization
- enable the **meson-build-xpack** project
- in Setting, disable **Build pushed branches** and **Build pull requests**

## Test work flow

Travis tests are manually triggered, and use the files in the project repo,
so it is necessary to push latest changes in the `xpack-develop` branch
to GitHub.

The first step is one of the top `trigger-travis-*.sh` scripts,
which call a helper `trigger_travis()` function that posts a http
request via `curl` to the Travis API.

The test configurations are passed in the request JSON as an array of
jobs, that each execute several script lines in the context of a given OS.

For Linux tests, these script lines call the same
`tests/scripts/docker-test.sh` but with different docker images.

For macOS and Windows, these scripts call `tests/scripts/native-test.sh`.

The Windows tests run in a Git BASH environment, so
the same scripts used for Linux and macOS can be used on Windows too.

The `docker-test.sh` invokes the helper `docker_run_test()` or
`docker_run_test_32()` functions, which use `docker run` and two volumes,
with the work folder and the git repo. It finally runs the
`tests/scripts/container-test.sh`, which includes the
`tests/scripts/common-functions-source.sh`, where the tests are actually
located.

When running native tests, the flow is significantly shorter,
the `tests/scripts/native-test.sh` can directly include
`tests/scripts/common-functions-source.sh` and call the test functions.

## Travis test results

The test results will be available at

- https://travis-ci.org/github/xpack-dev-tools/meson-build-xpack

## `common-functions-source.sh`

Both the native and container scripts call the public function
`run_tests()`, which in turn calls various local functions.

## Native test

The script to run the test as native on the current host mainly requires
the URL of the folder where the archives are stored:

```console
bash ~/Downloads/meson-build-xpack.git/tests/scripts/native-test.sh \
  https://github.com/xpack-dev-tools/pre-releases/releases/download/test/
```

Aditional options are `--32` (which must be given first).

## Rerun test

The script uses a cache, so if the script is invoked multiple times,
the archive is not downloaded each time.

To force a new download, remove the cached archive:

```console
rm ~/Work/cache/xpack-meson-build-*
```

## Main tests

The main purpose of these tests (implemented in the
`tests/scripts/common-functions-source.sh` script)
is to ckeck if the binaries are selfcontained
and can be started properly.

## GitHub API endpoint

Programatic access to GitHub is done via the v3 API:

- https://developer.github.com/v3/

```console
curl -i https://api.github.com/users/ilg-ul/orgs

curl -i https://api.github.com/repos/xpack-dev-tools/meson-build-xpack/releases

curl -v -X GET https://api.github.com/repos/xpack-dev-tools/meson-build-xpack/hooks
```

For authenticated requests, preferably create a new token and pass it
via the environment.

- https://developer.github.com/v3/#authentication

## Trigger GitHub action

To trigger a GitHub action it is necessary to send an authenticated POST
at a specific URL:

- https://developer.github.com/v3/repos/#create-a-repository-dispatch-event

```console
curl \
  --include \
  --header "Authorization: token ${GITHUB_API_DISPATCH_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/vnd.github.everest-preview+json" \
  --data '{"event_type": "on-demand-test", "client_payload": {}}' \
  https://api.github.com/repos/xpack-dev-tools/meson-build-xpack/dispatches
```

The request should return `HTTP/1.1 204 No Content`.

The repository should have an action with `on: repository_dispatch`.
