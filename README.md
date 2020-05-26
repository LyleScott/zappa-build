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

## Usage

Check out as a submodule in the root of your project:

```bash
git submodule add https://github.com/LyleScott/zappa-build zappa_build
```

Build the app:

```bash
docker build -t zappa_build -f zappa_build/Dockerfile .
```

Run the app:

```bash
docker run -it -v $(pwd)/zbuilds:/zbuilds zappa_build dev
```

## Example Deploy Script

It is easy to integrate `zappa-build` into your project seemlessly!

Given an example project hierarchy:

```
src/zappa_settings.json
src/manage.py
zappa_build/
```

> `zappa_build/` is from a `git submodule add https://github.com/LyleScott/zappa-build zappa_build`

You may have a script to deploy zappa like the following where a docker container does the main zappa build and lambda packaging in a Lambda-like environment and then follows up with some typical Dango post-deployment commands. 

```bash
#!/usr/bin/env bash

set -ex

S3Bucket=s3-bucket-to-store-sideload-tar.gz

EnvName=$1

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

# Build zappa in a Lambda like environment and produce a .zip and .tar.gz 
docker build -t zappa_build -f zappa_build/Dockerfile .
docker run -it -v $(pwd)/zappa_build/_builds:/zbuilds zappa_build ${EnvName}

# Head on in to the src directory containing `zappa_settings.yml`
pushd src

dot_tar_gz=$(ls -tr ../zappa_build/_builds/*.tar.gz | tail -n 1)
dot_zip=$(ls -tr ../zappa_build/_builds/*.zip | tail -n 1)
aws s3 cp ${dot_tar_gz} s3://${S3Bucket}/
aws s3 cp ${dot_zip} s3://${S3Bucket}/
if ! zappa deploy ${EnvName} -z s3://${S3Bucket}/$(basename $dot_zip); then
    zappa update ${EnvName} -z s3://${S3Bucket}/$(basename $dot_zip)
fi
zappa manage ${EnvName} 'collectstatic --noinput'
zappa manage ${EnvName} 'migrate --no-input'
zappa tail ${EnvName}
```
