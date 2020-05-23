#!/usr/bin/env bash
set -e

EnvName=$1o

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

source /venv/bin/activate

find . -name __pycache__ | xargs rm -rf
find . -name \*.pyc | xargs rm -f

python -m compileall -q .

zappa package --no_venv
mv *-zappa-${EnvName}-*.tar.gz /zbuilds

