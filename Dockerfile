FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim

# Add argument for metric (default to fa)
ARG METRIC=fa

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git g++ python3 libeigen3-dev zlib1g-dev libqt5opengl5-dev \
    libqt5svg5-dev libgl1-mesa-dev libblas-dev liblapack-dev \
    && rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Clone and build MRtrix3
WORKDIR /opt
RUN git clone https://github.com/MRtrix3/mrtrix3.git && \
    cd mrtrix3 && \
    ./configure && ./build

# Add MRtrix3 to system PATH for all users
RUN echo 'export PATH="/opt/mrtrix3/bin:$PATH"' > /etc/profile.d/mrtrix3.sh && \
    chmod +x /etc/profile.d/mrtrix3.sh

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy
# ENV SETUPTOOLS_USE_DISTUTILS=stdlib

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
ADD . /opt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/opt/.venv/bin:$PATH"

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

# Run the command
RUN chmod +x /opt/run_metric.sh
CMD ["/opt/run_metric.sh", "--metric", "${METRIC}"]