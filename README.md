# zappa-builder

Build a Zappa app within a docker container that mimicks the lambda env.

> The work here is for a Django app, so edit to taste.

## Usage

Check out as a submodule in the root of your project:

```bash
git submodule add https://github.com/LyleScott/zappa-builder zappa_build
```

Build the app:

```bash
docker build -t zappabuild -f zappa_build/Dockerfile .
```

Deploy the app:

```bash
# Mount your AWS keys so you have boto3 credentials.
docker run -it -v ~/.aws:/root/.aws zappabuild dev
```

```bash
# If you need to use an AWS profile:
docker run -it \
  -v ~/.aws:/root/.aws \
  -e AWS_PROFILE=prod \
  zappabuild dev
```

```bash
# You may also use environment variables if you only have AWS keys.
docker run -it \
  -e AWS_ACCESS_KEY_ID=foobar \
  -e AWS_SECRET_ACCESS_KEY=foobar \
  -e AWS_DEFAULT_REGION=us-east-1
```
