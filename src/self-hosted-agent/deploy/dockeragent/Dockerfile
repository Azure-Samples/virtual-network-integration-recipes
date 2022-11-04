# expiry 2022-06-09
# https://eng.ms/docs/more/containers-secure-supply-chain/next-step#what-is-timebombexpiry-date
# https://eng.ms/docs/more/containers-secure-supply-chain/approved-images#base-os-images
FROM mcr.microsoft.com/oss/mirror/docker.io/library/ubuntu:18.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  jq \
  git \
  iputils-ping \
  libcurl4 \
  libicu60 \
  libunwind8 \
  netcat \
  zip \
  unzip \
  gnupg \
  software-properties-common \
  libssl1.0 \
  && rm -rf /var/lib/apt/lists/*

RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
  && rm -rf /var/lib/apt/lists/*
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install -y --no-install-recommends \
  terraform \
  && rm -rf /var/lib/apt/lists/*

RUN apt-add-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3.8-dev \
  python3.8-venv \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /azp
RUN mkdir _work \
  && cd _work \
  && mkdir _tool \
  && cd _tool \
  && mkdir Python \
  && cd Python \
  && mkdir 3.8.11 \
  && cd 3.8.11 \
  && python3.8 -m venv x64 \
  && touch x64.complete 

ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]