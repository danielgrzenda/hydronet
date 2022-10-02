FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

ENV IMG_NAME=11.3.1-cudnn8-devel-ubuntu20.04 \
    JAXLIB_VERSION=0.3.15

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install --no-install-recommends -y build-essential gcc curl git software-properties-common openssh-client gnupg2 && \
    add-apt-repository universe && add-apt-repository ppa:deadsnakes/ppa

RUN apt -y update && apt -y install python3.9 python3.9-distutils python3.9-dev && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py

RUN pip install --pre torch torchvision torchaudio -f https://download.pytorch.org/whl/nightly/cu113/torch_nightly.html

RUN pip install --upgrade "jax[cpu]"
# RUN pip install --upgrade "jax[cuda]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.htm

COPY ./requirements.txt /tmp/req.txt
RUN pip install --no-cache-dir --user -r /tmp/req.txt

COPY . /hydronet/.
# RUN python3 -m pip install --user -e /hydronet/.

ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /hydronet

