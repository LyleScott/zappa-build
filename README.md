# zappa-build

Build a Zappa app within a docker container that mimics the Lambda environment.

Since `zappa` `deploy`/`update` desires an active virtualenv, this build creates a virtual env and
installs _only_ `requirements.txt` so that the resultant Lambda deployment `zip` is as small as
possible and has the least number of dependencies. This is also helpful when you deploy from your
workstation where you'd most likely have `requirements.dev.txt` or other python packages outside of
`requirements.txt`; these would make their way into the deployable code that gets side-loaded into
the Lambda causing bloat and possible errors due to size limits.

You'll also want to use an isolated build when you are building dependencies that require C
libraries, especially if your host system is not Amazon Linux. This helps minimize build vs run 
environment differences.

> The work here is for a Django app, so edit to taste.

**This is expecting `slim_handler=true` in `zappa_settings.json`, but PRs welcome...**

## Usage

Check out as a submodule in the root of your project:

```bash
git submodule add https://github.com/LyleScott/zappa-build zappa_build
```

Build the docker container:

```bash
docker build -t zappa_build -f zappa_build/Dockerfile .
```

Run the docker container with the right `EnvName` to produce build artifacts that will be used to update the zappa Lambda code.

```bash
docker run -it -v $(pwd)/zbuilds:/zbuilds zappa_build dev
# produces:
# the actual app code that's sideloaded with `slim_handler=true`
# zappa_build/_builds/prfoo-zappa-lyle-1590469643.tar.gz
# the Lambda code to bootstrap with (that sideloads the actual Lambda code)
# zappa_build/_builds/handler_prfoo-zappa-lyle-1590469760.zip
```

## Example Deploy Script

It is easy to integrate `zappa-build` into your project!

Given an example project hierarchy:

```
src/zappa_settings.json     # zappa app root is in src
scripts/deploy.sh           # the script below
zappa_build/                # zappa-build git submodule
```

> `zappa_build/` is from a `git submodule add https://github.com/LyleScott/zappa-build zappa_build`

You may have a script to deploy zappa like the following where a docker container does the main zappa build and Lambda packaging in a Lambda-like environment and then follows up with some typical Django post-deployment commands. 

```bash
#!/usr/bin/env bash

set -ex

EnvName=$1
S3Bucket="s3-bucket-to-house-zappa-deploy-files"

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

docker build -t zappa_build -f zappa_build/Dockerfile .
docker run -it -v $(pwd)/zappa_build/_builds:/zbuilds zappa_build ${EnvName}

# Grab the latest builds and push to S3.
dot_tar_gz=$(ls -tr zappa_build/_builds/*.tar.gz | tail -n 1)
dot_zip=$(ls -tr zappa_build/_builds/*.zip | tail -n 1)
aws s3 cp ${dot_tar_gz} s3://${S3Bucket}/
aws s3 cp ${dot_zip} s3://${S3Bucket}/

# Zappa foo (directory contains zappa_settings.json)
pushd src
if ! zappa deploy ${EnvName} -z s3://${S3Bucket}/$(basename $dot_zip); then
    zappa update ${EnvName} -z s3://${S3Bucket}/$(basename $dot_zip)
fi
zappa manage ${EnvName} 'collectstatic --noinput'
zappa manage ${EnvName} 'migrate --no-input'
zappa tail ${EnvName}
```
