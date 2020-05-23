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

You have a few options for telling the container about your AWS credentials that boto needs:

Mount your AWS credentials and config files:

```bash
docker run -it \
    -v ~/.aws:/root/.aws \
    -v $(pwd)/zbuilds:/zbuilds \
    zappa_build dev
```

If you needed to specify a profile to use from `/root/.aws/credentials`:

```bash
docker run -it \
  -v ~/.aws:/root/.aws \
  -v $(pwd)/zbuilds:/zbuilds \
  -e AWS_PROFILE=prod \
  zappa_build dev
```

If you needed to use environment variables:

> These are likely defined in your `~/.aws/credentials` file

```bash
docker run -it \
  -v $(pwd)/zbuilds:/zbuilds \
  -e AWS_ACCESS_KEY_ID=foobar \
  -e AWS_SECRET_ACCESS_KEY=foobar \
  -e AWS_DEFAULT_REGION=us-east-1 \
  zappa_build dev
```
