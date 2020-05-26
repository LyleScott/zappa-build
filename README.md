# zappa-build

Build a Zappa app within a docker container that mimicks the lambda env.

Since the `deploy`/`update` wants you to have an active virtualenv, this build creates a new virtual env and installs only `requirements.txt` so that the resultant lambda zip is as small as possible and has only the deps defined (ie, you'll probably have dev stuff installed locally). 

You'll want to do this when you are building dependencies that require C libraries. Otherwise, you run the risk of building packages in an environment (locally) very different than the execution environment (lambda).

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

It is easy to integration `zappa-build` into your project seemlessly.

Given an example project hierarchy:

```
src/zappa_settings.json
src/manage.py
```

You may have a script to deploy zappa like the following where a docker container does the main zappa build and lambda packaging in a Lambda-like environment and then some useful `zappa` commands are done. 


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
