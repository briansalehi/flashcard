FROM alpine:latest
LABEL maintainer="Brian Salehi <salehibrian@gmail.com>"
LABEL description="Language Learning Flashcard"
LABEL version="v0.1.0"

RUN apk add --update cmake g++

COPY . /src

RUN cmake -S /src -B /build -D CMAKE_BUILD_TYPE:STRING="Release" -D CMAKE_PREFIX_PATH:PATH="/usr/local" -j $(nproc)
RUN cmake --install /build -j $(nproc)

VOLUME flashcard

EXPOSE 4498

ENTRYPOINT ["/usr/local/bin/flashcard"]
