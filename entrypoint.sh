#!/usr/bin/env bash
set -e

EnvName=$1

if [[ -z ${EnvName} ]]; then
    echo "USAGE: <env-name>"
    exit 1
fi

find . -name __pycache__ | xargs rm -rf
find . -name \*.pyc | xargs rm -f

python -m compileall -q .
source /venv/bin/activate

zappa package
mv *-zappa-${EnvName}-*.* /zbuilds

