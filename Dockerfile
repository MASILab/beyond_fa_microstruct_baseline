FROM mrtrix3/mrtrix3:latest

# Copy uv binaries to install Python
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Add a non-root user
RUN groupadd -r user && useradd --no-log-init -r -g user user

# Copy code as root first
COPY . /code
RUN chown -R user:user /code

# Install Python dependencies using UV
RUN mkdir -p /code/.cache/matplotlib
ENV MPLCONFIGDIR=/code/.cache/matplotlib
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_CACHE_DIR=/code/.cache/uv
ENV UV_PYTHON_INSTALL_DIR=/code/python
WORKDIR /code

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev \
    && uv sync --frozen --no-dev

# Create entrypoint script that handles permissions
RUN echo '#!/bin/bash\n\
mkdir -p /output\n\
chown -R user:user /output\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/code/scripts/entrypoint.sh"]
