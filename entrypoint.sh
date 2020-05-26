#!/usr/bin/env bash
set -e

EnvName=$1

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

# Cleanup (in the Docker image only)
find . -name __pycache__ -o -name \*.pyc | xargs rm -rf
python -m compileall -q .

# Zappa forces you into a venv. There's an option to not
# use it, but there are bugs.
source /venv/bin/activate

# Since we are using the slim_handler, this creates 2 files:
# - A .zip that is the code to bootstrap lambda and
#   downloads/extracts the .tar.gz
# - A .tar.gz that is the full code of the fatty lambda that
#   has been sent to S3 to side-load.
zappa package

# Move build artifacts to a directory that is mounted on the
# host so that they are available to zappa commands on the host.
mv *-zappa-${EnvName}-*.* /zbuilds
