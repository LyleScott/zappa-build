FROM lambci/lambda:build-python3.7

ENV PYTHONUNBUFFERED 1

RUN python3 -m venv /venv
ADD requirements.txt /venv/requirements.txt
RUN source /venv/bin/activate &&\
    pip3 install -r /venv/requirements.txt

ADD . /code
WORKDIR /code/src
ENTRYPOINT ["/code/zappa_build/deploy.sh"]
