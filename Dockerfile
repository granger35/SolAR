# Adapted from https://solarframework.github.io/install/linux/
FROM ubuntu:18.04

# Install essentials
RUN set -eux && \
    apt-get update && \
    apt-get install -y git curl wget zip pkg-config sudo swig openjdk-8-jre-headless build-essential clang libgoogle-glog-dev libatlas-base-dev libeigen3-dev libsuitesparse-dev cmake python-pip openssh-server npm

# Build tools
RUN set -eux &&  \
    apt-get install -y qt5-default &&  \
    apt-get install -y g++

# Install github-release-cli
RUN npm install -g github-release-cli

# Install brew
RUN apt-get install locales && localedef -i en_US -f UTF-8 en_US.UTF-8
RUN git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew && \
    mkdir /home/linuxbrew/.linuxbrew/bin && \
    ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin && \
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
    brew --version

ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
ENV LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/Cellar/python@3.8/3.8.2_1/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH ="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
ENV REMAKEN_RULES_ROOT="/root/.remaken/rules/"

RUN set -eux \
    && mkdir -p /root/.remaken/

# Install remaken
RUN set -eux && \
    brew tap b-com/sft && \
    brew install remaken
# Configure remaken
RUN remaken init --tag latest
RUN remaken profile init --cpp-std 17 -b gcc -o linux -a x86_64

# Configure conan
RUN conan profile new default --detect && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.compiler.cppstd=17 default
RUN conan remote add conan-solar https://artifact.b-com.com/api/conan/solar-conan-local

# Install SolAR dependencies
WORKDIR /tmp
COPY ./packagedependencies.txt /tmp
COPY ./packagedependencies-linux.txt /tmp
RUN remaken install packagedependencies.txt
RUN remaken install -c debug packagedependencies.txt

WORKDIR /project
