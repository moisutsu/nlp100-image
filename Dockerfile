FROM ubuntu:18.04

# GoogleDriveからCaboChaをインストールするために必要な値
ENV FILE_ID 0B4y35FiV1wh7SDd1Q1dUQkZQaUU
ENV FILE_NAME cabocha-0.69.tar.bz2

#必要なライブラリをインストール
RUN apt-get update && \
    apt-get install -y python3 \
    python3-pip \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8 \
    git \
    curl \
    sudo \
    swig \
    python-dev

# MeCabをインストール
RUN git clone https://github.com/neologd/mecab-ipadic-neologd.git && \
    mecab-ipadic-neologd/bin/install-mecab-ipadic-neologd -y -n && \
    echo "dicdir = /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd" > /etc/mecabrc && \
    pip3 install mecab-python3 && \
    curl -L -o CRF++-0.58.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ" && \
    tar zxfv CRF++-0.58.tar.gz && \
    cd CRF++-0.58 && \
    ./configure && \
    make && \
    make install && \
    cd ..

# CaboChaをインストール
RUN curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${FILE_ID}" > /dev/null && \
    CODE="$(awk '/_warning_/ {print $NF}' /tmp/cookie)" && \
    curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${CODE}&id=${FILE_ID}" -o ${FILE_NAME} && \
    bzip2 -dc cabocha-0.69.tar.bz2 | tar xvf - && \
    cd cabocha-0.69 && \
    ./configure --with-mecab-config=`which mecab-config` --with-charset=UTF8 && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/lib.conf && \
    echo "/usr/local/lib" >> /etc/ld.so.conf && \
    ldconfig && \
    make && \
    make check && \
    make install && \
    cd python && \
    python3 setup.py build_ext && \
    python3 setup.py install && \
    ldconfig

# Ubuntuの日本語化
RUN apt-get install language-pack-ja-base language-pack-ja && \
    locale-gen ja_JP.UTF-8 && \
    echo export LANG=ja_JP.UTF-8 >> ~/.profile && \
    source ~/.profile
