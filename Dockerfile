FROM neurodebian:non-free
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Required for installing scilpy and tractseg
RUN apt update && apt install -y \
    git \
    wget \
    build-essential \
    libblas-dev \
    liblapack-dev 
ENV SETUPTOOLS_USE_DISTUTILS=stdlib

# # Install FSL and mrtrix (available through Neurodebian)
RUN apt-get update && apt-get install -y \
    fsl \
    mrtrix3

# Install Python from UV (see https://docs.astral.sh/uv/guides/integration/docker)
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ADD . /opt
WORKDIR /opt

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/opt/.venv/bin:$PATH"

# Download TractSeg weights and set $TRACTSEG_WEIGHTS_DIR
RUN mkdir -p /model/tractseg && \
    wget -O /model/tractseg/pretrained_weights_tract_segmentation_v3.npz \
    https://zenodo.org/records/3518348/files/best_weights_ep220.npz?download=1
RUN echo 'export TRACTSEG_WEIGHTS_DIR="/model/tractseg"' > /etc/profile.d/tractseg.sh && \
    chmod +x /etc/profile.d/tractseg.sh

# Run entrypoint with environment variables METRIC from Dockerfile
COPY ./scripts/* /opt
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/run_metric.sh /entrypoint.sh
ENV METRIC=fa
ENTRYPOINT ["/bin/bash"]