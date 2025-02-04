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

# Install FSL
RUN apt-get update && apt-get -y install python-is-python3 wget ca-certificates \
    libglu1-mesa libgl1-mesa-glx libsm6 \
    libice6 libxt6 libpng16-16 libxrender1 libxcursor1 libxinerama1 libfreetype6 libxft2 \
    libxrandr2 libgtk2.0-0 libpulse0 libasound2 libcaca0 libopenblas-dev bzip2 dc bc file
RUN wget -O /opt/fslinstaller.py "https://git.fmrib.ox.ac.uk/fsl/installer/-/raw/3.3.0/fslinstaller.py?inline=false"
RUN python /opt/fslinstaller.py -d /opt/fsl -V 6.0.3
# RUN echo 'export PATH="/opt/fsl/bin:$PATH"' > /etc/profile.d/fsl.sh && \
#     chmod +x /etc/profile.d/fsl.sh
RUN echo "export FSLDIR=/opt/fsl && . /opt/fsl/etc/fslconf/fsl.sh && \
    export PATH=/opt/fsl/bin:${PATH} && \
    export FSLOUTPUTTYPE=NIFTI_GZ" >> /etc/profile.d/fsl.sh && \
    chmod +x /etc/profile.d/fsl.sh

# Enable bytecode compilation
ENV PYTOHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1
# ENV PYTHONIOENCODING=UTF-8

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy
ENV SETUPTOOLS_USE_DISTUTILS=stdlib

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

# Download TractSeg weights and set $TRACTSEG_WEIGHTS_DIR
RUN mkdir -p /model/tractseg && \
    wget -O /model/tractseg/pretrained_weights_tract_segmentation_v3.npz \
    https://zenodo.org/records/3518348/files/best_weights_ep220.npz?download=1
RUN echo 'export TRACTSEG_WEIGHTS_DIR="/model/tractseg"' > /etc/profile.d/tractseg.sh && \
    chmod +x /etc/profile.d/tractseg.sh

# Run entrypoint with environment variables METRIC from Dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/run_metric.sh /entrypoint.sh
ENV METRIC=${METRIC}
ENTRYPOINT ["/entrypoint.sh"]

# # Run the command
# RUN chmod +x /opt/run_metric.sh
# CMD ["--metric", "${METRIC}"]