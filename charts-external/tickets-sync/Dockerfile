FROM python:2-alpine
RUN echo "http://nl.alpinelinux.org/alpine/v3.4/main" > /etc/apk/repositories &&\
    echo "http://nl.alpinelinux.org/alpine/v3.4/community" >> /etc/apk/repositories &&\
    apk --update --no-cache add mariadb-dev bash build-base &&\
    pip install sqlalchemy mysql
COPY entrypoint.py /tickets-sync/
ENTRYPOINT ["python", "/tickets-sync/entrypoint.py"]
