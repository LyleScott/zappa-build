#!/usr/bin/env bash
set -e

EnvName=$1

source /venv/bin/activate

find . -name __pycache__ | xargs rm -rf
find . -name \*.pyc | xargs rm -f

python -m compileall -q .

#zappa deploy ${EnvName}
zappa update ${EnvName}
zappa manage ${EnvName} 'collectstatic --noinput'
zappa manage ${EnvName} 'migrate --no-input'
zappa schedule ${EnvName}
zappa tail ${EnvName}
