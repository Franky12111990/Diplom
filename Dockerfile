###########
# BUILDER #
###########

# pull official base image
FROM python:3.11-alpine as builder

# set work directory
WORKDIR /app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install system dependencies
RUN apk update \
    && apk add pkgconfig gcc musl-dev mariadb-dev mariadb-connector-c-dev\
    && rm -rf /var/lib/apk/lists/*

RUN pip install --upgrade pip 

# install python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir  --wheel-dir /usr/src/app/wheels -r requirements.txt

#########
# FINAL #
#########

# pull official base image
FROM python:3.11-alpine

RUN apk add --no-cache curl busybox-extras

# create directory for the app user
RUN mkdir -p /home/app

# create the app user
RUN addgroup --system app && adduser -S app -G app

# create the appropriate directories
ENV HOME=/home/app
ENV APP_HOME=/home/app/web
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y libmariadb-dev

# install dependencies
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache /wheels/*

RUN apk add mariadb-connector-c-dev busybox-suid

# copy project
COPY . $APP_HOME

# chown all the files to the app user
RUN chown -R app:app $APP_HOME
RUN chmod +x entrypoint.prod.sh
# change to the app user
USER app
ENV PYTHONUNBUFFERED 1
CMD ["./entrypoint.sh"]
