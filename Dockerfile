FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim

# Install dependencies & MRtrix3 in a single layer to minimize image size
RUN apt-get update && apt-get install -y \
    git g++ python3 libeigen3-dev zlib1g-dev libqt5opengl5-dev \
    libqt5svg5-dev libgl1-mesa-dev libblas-dev liblapack-dev \
    wget file dc mesa-utils pulseaudio libquadmath0 libgtk2.0-0 libgomp1 \
    && git clone --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3 \
    && cd /opt/mrtrix3 && ./configure && NUMBER_OF_PROCESSORS=1 ./build \
    && echo 'export PATH="/opt/mrtrix3/bin:$PATH"' > /etc/profile.d/mrtrix3.sh \
    && chmod +x /etc/profile.d/mrtrix3.sh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install FSL
ENV FSLDIR="/usr/local/fsl"
ENV DEBIAN_FRONTEND="noninteractive"
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py \
    && python ./fslinstaller.py -d /usr/local/fsl/ \
    && echo ". /usr/local/fsl/etc/fslconf/fsl.sh" >> /etc/profile.d/fsl.sh \
    && chmod +x /etc/profile.d/fsl.sh \
    && rm -f fslinstaller.py

# Install scilpy & tractseg dependencies
RUN apt-get update && apt-get install -y \
    build-essential libblas-dev liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies using UV
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ADD . /opt
WORKDIR /opt

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev \
    && uv sync --frozen --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/opt/.venv/bin:${PATH}"

# Download TractSeg weights
RUN mkdir -p /model/tractseg \
    && wget -O /model/tractseg/pretrained_weights_tract_segmentation_v3.npz \
    https://zenodo.org/records/3518348/files/best_weights_ep220.npz?download=1
ENV TRACTSEG_WEIGHTS_DIR="/model/tractseg"

# Add a non-root user
RUN groupadd -r user && useradd --no-log-init -r -g user user

# Copy scripts & set permissions
COPY ./scripts/* /opt/
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/run_metric.sh /entrypoint.sh && chmod 777 /opt

# Set metric environment variable
ENV METRIC=fa

USER user
ENTRYPOINT ["/entrypoint.sh"]
