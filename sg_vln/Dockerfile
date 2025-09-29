ARG BASE_IMAGE=nvcr.io/nvidia/isaac-sim
ARG IMAGE_TAG=5.0.0
FROM ${BASE_IMAGE}:${IMAGE_TAG} AS system

# DEVCONTAINER SPECIFIC
ARG USERNAME=USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Make user/group creation tolerant of preexisting GID 1000
RUN set -e; \
    # If a user with this UID exists, remove it (find by UID, not name)
    if getent passwd "$USER_UID" >/dev/null; then \
      userdel -r -f "$(getent passwd "$USER_UID" | cut -d: -f1)" || true; \
    fi; \
    # Create the group only if the GID doesn't already exist (Jetson image has it)
    if ! getent group "$USER_GID" >/dev/null; then \
      groupadd -g "$USER_GID" "$USERNAME"; \
    fi; \
    # Create the user bound to that UID/GID
    useradd -m -u "$USER_UID" -g "$USER_GID" "$USERNAME"; \
    apt-get update && apt-get install -y sudo; \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"; \
    chmod 0440 /etc/sudoers.d/"$USERNAME"

# Optimize apt caching
# Basically we are disabling docker-clean to make repetitive image building faster, 
#   packages should still be removed when docker is pruned
RUN mv /etc/apt/apt.conf.d/docker-clean /etc/apt/ && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8

# install libraries and tools
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo \
    dialog \
    apt-utils \
    git \
    mercurial \
    pkg-config \
    mesa-utils \
    libxau-dev \
    libxdmcp-dev \
    libxcb1-dev \
    libxext-dev \
    libx11-dev \ 
    git \
    tmux \
    wget \
    curl \
    cmake \
    vim \ 
    build-essential \
    unzip \
    autoconf \
    autogen \
    automake \
    libtool \
    mlocate \
    zlib1g-dev \
    libopenblas-dev \
    libflann-dev \
    libboost-all-dev \
    libsuitesparse-dev \
    libtbb-dev \
    libusb-1.0-0-dev \
    libgtest-dev \
    pkg-config \
    cmake-curses-gui \
    gdb \
    clang \
    emacs \
    libpcap-dev \
    gnupg2 \
    x11-xserver-utils \
    lsb-release \
    tilix \
    zsh \
    python3-dev \
    python3-pip \
    python3-tk \
    python3-matplotlib \
    valgrind \
    kcachegrind

# --- Install ROS2
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt-get install software-properties-common -y \
    && add-apt-repository universe -y \
    && apt-get update \
    && export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}') \
    && curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" \
    && dpkg -i /tmp/ros2-apt-source.deb

# Why are we removing librotli1?
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt-get update \
    && apt-get remove libbrotli1 -y \
    && apt-get install -y ros-humble-desktop

## Update cmake
# Why are we installing some third-party version of cmake?
# RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
#     apt-get update \
#     && apt-get install -y --no-install-recommends software-properties-common \
#     && wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
#     && dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
#     && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - \
#     && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ noble main' \
#     && apt-get install -y --no-install-recommends cmake \
#     && gcc --version

# install zsh
COPY scripts/zsh zsh
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt-get install -y --no-install-recommends git
RUN cd zsh && bash install_zsh.sh

# install gitstatus
RUN mkdir -p /root/.cache/gitstatus \
    && wget https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-x86_64.tar.gz -O - \
    | tar -zx -C /root/.cache/gitstatus/

# --- Install conda and environment
ENV CONDA_DIR /root/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p ${CONDA_DIR}
ENV PATH $CONDA_DIR/bin:$PATH
ENV PATH_BACKUP $PATH
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main --channel https://repo.anaconda.com/pkgs/r
RUN conda create -n webvnc python=3.6
ENV PATH $CONDA_DIR/envs/webvnc/bin:$PATH_BACKUP

# --- Install webvnc
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt update \
    && apt install -y --no-install-recommends software-properties-common curl apache2-utils \
    && apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
    supervisor nginx net-tools zenity xz-utils \
    dbus-x11 x11-utils alsa-utils \
    mesa-utils libgl1-mesa-dri \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
    xvfb x11vnc \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
    lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine arc-theme \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# tini to fix subreap
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

# ffmpeg
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /usr/local/ffmpeg \
    && ln -s /usr/bin/ffmpeg /usr/local/ffmpeg/ffmpeg

RUN git clone --recurse-submodules https://github.com/tccoin/docker-ubuntu-vnc-desktop.git /webvnc
RUN pip3 install backports.ssl-match-hostname==3.7.0.1 certifi==2019.9.11 chardet==3.0.4 Click==7.0 Flask==1.1.1 Flask-Login==0.4.1 idna==2.8 itsdangerous==1.1.0 Jinja2==2.10.3 MarkupSafe==1.1.1 meld3==2.0.0 requests==2.22.0 six==1.12.0 urllib3==1.25.6 websocket-client==0.47.0 Werkzeug==0.16.0 gevent gevent-websocket greenlet
# RUN pip3 install -r /webvnc/rootfs/usr/local/lib/web/backend/requirements.txt

# builder
FROM ubuntu:22.04 AS builder
RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg patch
# nodejs
RUN curl -L https://deb.nodesource.com/nsolid_setup_deb.sh | bash -s -- 18 \
    && apt-get install nodejs -y
# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -qy yarn git
# build frontend
RUN git clone --recurse-submodules https://github.com/tccoin/docker-ubuntu-vnc-desktop.git /webvnc
RUN cd /webvnc/web \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /webvnc/web/dist/static/novnc/app/ui.js
# merge
FROM system

ARG IMAGE_TAG=5.0.0

COPY --from=builder /webvnc/web/dist/ /usr/local/lib/web/frontend/
RUN cp -r /webvnc/rootfs/* /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
    chmod +x /usr/local/lib/web/frontend/static/websockify/run

WORKDIR /dependencies
RUN pip uninstall -y urllib3 && pip install urllib3
RUN conda create --name vln python=3.11
ENV PATH $CONDA_DIR/envs/vln/bin:$PATH
SHELL ["conda", "run", "-n", "vln", "/bin/bash", "-c"]

# CUDA toolkit only (no driver) for nvcc
RUN apt-get update && apt-get install -y wget gnupg ca-certificates
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring_1.1-1_all.deb && rm cuda-keyring_1.1-1_all.deb && apt-get update
# Match your PyTorch wheels. For 5090 support use CUDA 12.8+.
RUN apt-get install -y cuda-toolkit-12-8

ENV CUDA_HOME=/usr/local/cuda-12.8
ENV CUDAToolkit_ROOT=${CUDA_HOME}
ENV PATH=${CUDA_HOME}/bin:$PATH
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:$LD_LIBRARY_PATH

# --- Install habitat-sim
RUN git clone --branch v0.3,3 https://github.com/facebookresearch/habitat-sim.git
RUN cd habitat-sim \
    && pip install -r requirements.txt \
    && python setup.py install --headless --with-cuda --bullet

# --- Install habitat-lab
RUN git clone --branch v0.3.3 https://github.com/facebookresearch/habitat-lab.git
RUN cd habitat-lab \
    && pip install -e habitat-lab


RUN apt-get update && apt-get install -y libgl1-mesa-dri libgl1-mesa-glx mesa-utils

# Good for 5090 (Blackwell) and 4090 (Ada)
ENV TORCH_CUDA_ARCH_LIST="8.9;12.0"
# Example: PyTorch 2.9 with CUDA 12.8 wheels
RUN pip install --index-url https://download.pytorch.org/whl/cu128 \
    torch==2.8.* torchvision==0.23.* torchaudio==2.8.*


# --- torch3d
RUN git clone https://github.com/facebookresearch/pytorch3d.git
RUN cd pytorch3d \
    && pip install -e .

RUN curl -fsSL https://ollama.com/install.sh | sh

RUN apt-get update && apt-get install -y openjdk-17-jdk-headless
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:$PATH

RUN pip install --only-binary=:all: "JPype1>=1.6.0"
RUN pip install --no-deps pslpython
RUN pip install open3d omegaconf git+https://github.com/openai/CLIP.git nltk einops ftfy scikit-fmm ollama openai matplotlib

ENV CUDA_HOME=/usr/local/cuda-12.8
ENV CUDAToolkit_ROOT=${CUDA_HOME}
ENV CUDA_PATH=${CUDA_HOME}
ENV PATH=${CUDA_HOME}/bin:$PATH
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:$LD_LIBRARY_PATH

# Make the common /usr/local/cuda path point at 12.8 so build tools auto-find it
RUN ln -sfn /usr/local/cuda-12.8 /usr/local/cuda

# Speed up extension builds
RUN apt-get update && apt-get install -y ninja-build && pip install ninja

# Target both 4090 (sm_89) and 5090 (sm_120)
ENV TORCH_CUDA_ARCH_LIST="8.9;12.0"
ENV CMAKE_CUDA_ARCHITECTURES="89;120"

# --- Install Ground-SAM
RUN git clone https://github.com/IDEA-Research/Grounded-Segment-Anything.git && \
    cd Grounded-Segment-Anything && \
    git submodule update --init --recursive
WORKDIR /dependencies/Grounded-Segment-Anything
RUN git clone https://github.com/mattmazzola/Tag2Text.git
RUN wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
RUN wget https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth

ENV BUILD_WITH_CUDA 1
RUN python -m pip install --no-cache-dir -e segment_anything
RUN python -m pip install --upgrade pip
RUN python -m pip install --upgrade setuptools wheel twine check-wheel-contents
RUN python -m pip install --no-cache-dir wheel
RUN cd GroundingDINO && python setup.py install

# --- Fix library issues
RUN mkdir -p /usr/lib/dri/ && \
    ln -s /usr/lib/x86_64-linux-gnu/dri/swrast_dri.so /usr/lib/dri/ && \
    ln -s /usr/lib/x86_64-linux-gnu/dri/radeonsi_dri.so /usr/lib/dri/ && \
    mv /root/conda/envs/vln/lib/libstdc++.so.6 /root/conda/envs/vln/lib/libstdc++.so.6.old && \
    ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /root/conda/envs/vln/lib/libstdc++.so.6

# --- Install SG-VLN dependencies
WORKDIR /dependencies
RUN git clone https://github.com/ybgdgh/VLN-Game
RUN cd VLN-Game && pip install -r requirements.txt
# 1) Preinstall a wheel that works with Python 3.11 (no source build)
RUN pip install --only-binary=:all: "JPype1>=1.5.0"

# 2) Install PSL but block it from downgrading JPype
RUN pip install --no-deps pslpython==2.4.0

# 3) Install the rest of your stack
RUN pip install scikit-fmm==2023.4.2 scikit-image ifcfg tensorboard ultralytics tyro open_clip_torch wandb h5py hydra-core yacs textblob
ENV GSA_PATH=/dependencies/Grounded-Segment-Anything
RUN pip install git+https://github.com/xinyu1205/recognize-anything.git
RUN pip uninstall -y open3d
RUN pip install open3d==0.19.0
RUN conda install -y pytorch::faiss-gpu
RUN pip install fairscale supervision==0.25.0 transformers==4.49.0 scipy==1.11.2 opencv-python==4.9.0.80 watchdog ipython spatialmath-python
RUN pip install duckdb 'ibis-framework[duckdb]' pins gcsfs 
RUN pip install nvitop
RUN apt-get update && apt-get install -y htop
RUN pip install transformers datasets accelerate trl==0.19.0 peft huggingface-hub bitsandbytes tensorboard pyyaml pillow tf-keras torchmetrics
RUN pip install yapf pycocotools
RUN pip install --upgrade --no-cache-dir openai
# --- Download llama3.2-vision with ollama
# RUN ollama serve & sleep 5 ; ollama pull llama3.2-vision ; \
#     echo "kill 'ollama serve' process" ; \
#     ps -ef | grep 'ollama serve' | grep -v grep | awk '{print $2}' | xargs -r kill -9

# --- Install Isaac Lab and Isaac Sim
WORKDIR /dependencies
# RUN pip install isaacsim[all,extscache]==$IMAGE_TAG --extra-index-url https://pypi.nvidia.com
RUN git clone https://github.com/isaac-sim/IsaacLab.git \
    && cd IsaacLab \
    && git checkout v2.2.1
RUN ln -s /isaac-sim /dependencies/IsaacLab/_isaac_sim
RUN cd /dependencies/IsaacLab && ./isaaclab.sh --install

RUN pip install pygame jsonpickle

# Change /root to /workspace for singularity
RUN conda init bash
SHELL ["bash", "-c"]
RUN mv /root /workspace
RUN ln -s /workspace /root
WORKDIR /workspace