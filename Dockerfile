# A container that mimicks the execution environment in AWS Lambda.
# ! Make sure the Python version matches the Lambda's config !
FROM lambci/lambda:build-python3.7

ENV PYTHONUNBUFFERED 1

ADD requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

ADD . /code
WORKDIR /code/src
ENTRYPOINT ["/code/zappa_build/entrypoint.sh"]
