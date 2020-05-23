# zappa-builder

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

## Example Deploy

```bash
#!/usr/bin/env bash

EnvName=$1

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

docker build -t zappa_build -f zappa_build/Dockerfile .
docker run -it -v ~/.aws:/root/.aws -v $(pwd)/zbuilds:/zbuilds zappa_build dev

pushd src

#zappa deploy ${EnvName}
zappa update ${EnvName} -z ../$(ls -tr ../zbuilds | tail -n 1)
zappa manage ${EnvName} 'collectstatic --noinput'
zappa manage ${EnvName} 'migrate --no-input'
zappa schedule ${EnvName}
zappa tail ${EnvName}
```
