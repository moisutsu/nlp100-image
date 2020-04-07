FROM ubuntu:20.04

# GoogleDriveからCaboChaをインストールするために必要な値
ENV FILE_ID 0B4y35FiV1wh7SDd1Q1dUQkZQaUU
ENV FILE_NAME cabocha-0.69.tar.bz2

# 非対話的にライブラリをインストール
ENV DEBIAN_FRONTEND noninteractive

ENV LANG ja_JP.UTF-8

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
    python3-dev \
    language-pack-ja-base \
    language-pack-ja \
    fonts-noto-cjk \
    graphviz

# neologd(MeCab用の辞書)をインストール
RUN git clone https://github.com/neologd/mecab-ipadic-neologd.git && \
    mecab-ipadic-neologd/bin/install-mecab-ipadic-neologd -y -n && \
    echo "dicdir = /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd" > /etc/mecabrc

# CRF++をインストール
RUN curl -L -o CRF++-0.58.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ" && \
    tar zxfv CRF++-0.58.tar.gz && \
    cd CRF++-0.58 && \
    ./configure && \
    make && \
    make install

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
RUN locale-gen ja_JP.UTF-8

# Pythonでの必要なライブラリのインストール
RUN python3 -m pip install pylint mecab-python3 regex requests numpy matplotlib pydot graphviz

# matplotlibの日本語化
RUN echo "font.serif      : Noto Serif CJK JP, DejaVu Serif, DejaVu Serif, Bitstream Vera Serif, Computer Modern Roman, New Century Schoolbook, Century Schoolbook L, Utopia, ITC Bookman, Bookman, Nimbus Roman No9 L, Times New Roman, Times, Palatino" >> /usr/local/lib/python3.8/dist-packages/matplotlib/mpl-data/matplotlibrc && \
    echo "font.sans-serif : Noto Sans CJK JP, DejaVu Sans, Bitstream Vera Sans, Computer Modern Sans Serif, Lucida Grande, Verdana, Geneva, Lucid, Arial, Helvetica, Avant Garde, sans-serif" >> /usr/local/lib/python3.8/dist-packages/matplotlib/mpl-data/matplotlibrc && \
    rm -rf ~/.cache/matplotlib

COPY ./.bash_aliases /root/