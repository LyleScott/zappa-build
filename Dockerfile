# A container that mimicks the execution environment in AWS Lambda.
# ! Make sure the Python version matches the Lambda's config !
FROM lambci/lambda:build-python3.7

# See things as they happen.
ENV PYTHONUNBUFFERED 1

# The Zappa build requires an active virtualenv.
RUN python3 -m venv /venv
ADD requirements.txt /venv/requirements.txt
RUN source /venv/bin/activate &&\
    pip3 install -r /venv/requirements.txt

ADD . /code
WORKDIR /code/src
ENTRYPOINT ["/code/zappa_build/entrypoint.sh"]
