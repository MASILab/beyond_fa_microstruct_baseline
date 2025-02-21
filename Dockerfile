FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim

# Install mrtrix3
RUN apt-get update && apt-get install -y \
    git g++ python3 libeigen3-dev zlib1g-dev libqt5opengl5-dev \
    libqt5svg5-dev libgl1-mesa-dev libblas-dev liblapack-dev
WORKDIR /opt
RUN git clone https://github.com/MRtrix3/mrtrix3.git && \
    cd mrtrix3 && \
    ./configure && ./build

# Add MRtrix3 to system PATH for all users
RUN echo 'export PATH="/opt/mrtrix3/bin:$PATH"' > /etc/profile.d/mrtrix3.sh && \
    chmod +x /etc/profile.d/mrtrix3.sh

# Install FSL (https://fsl.fmrib.ox.ac.uk/fsl/docs/#/install/container)
ENV FSLDIR="/usr/local/fsl"
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt update  -y && \
    apt upgrade -y && \
    apt install -y    \
      python-is-python3\
      wget            \
      file            \
      dc              \
      mesa-utils      \
      pulseaudio      \
      libquadmath0    \
      libgtk2.0-0     \
      libgomp1
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py
RUN python ./fslinstaller.py -d /usr/local/fsl/

# Add FSL to system PATH for all users
ENV PATH="/usr/local/fsl/bin:${PATH}"
RUN echo ". /usr/local/fsl/etc/fslconf/fsl.sh" >> /etc/profile.d/fsl.sh && \
    chmod +x /etc/profile.d/fsl.sh

# Install scilpy and tractseg
RUN apt update && apt install -y \
    git \
    wget \
    build-essential \
    libblas-dev \
    liblapack-dev 
ENV SETUPTOOLS_USE_DISTUTILS=stdlib

# Install Python from UV (see https://docs.astral.sh/uv/guides/integration/docker)
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ADD . /opt

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/opt/.venv/bin:${PATH}"

# Download TractSeg weights and set $TRACTSEG_WEIGHTS_DIR
RUN mkdir -p /model/tractseg && \
    wget -O /model/tractseg/pretrained_weights_tract_segmentation_v3.npz \
    https://zenodo.org/records/3518348/files/best_weights_ep220.npz?download=1
ENV TRACTSEG_WEIGHTS_DIR="/model/tractseg"

# Add a non-root user
RUN groupadd -r user && useradd --no-log-init -r -g user user

# Run entrypoint with environment variables METRIC from Dockerfile
COPY ./scripts/* /opt
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/run_metric.sh /entrypoint.sh
RUN chmod 777 /opt
ENV METRIC=fa

USER user
ENTRYPOINT ["/entrypoint.sh"]