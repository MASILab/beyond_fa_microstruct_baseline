# Beyond FA Baseline

Here is an example repository for the Beyond FA challenge. This model calculates fractional anisotropy (FA) from the diffusion MRI, then finds the average value of FA in regions defined by [TractSeg](https://github.com/MIC-DKFZ/TractSeg).

## Building the Docker

See `Dockerfile` for an example of setting up the Docker container. The Docker container is based the mrtrix Docker, which includes several common neuroimaging packages (e.g., MRtrix3, ANTs, FSL, Freesurfer). It also installs the following:

- [`uv`](https://github.com/astral-sh/uv) for installing and running Python in a virtual environment
- [`TractSeg`](https://github.com/MIC-DKFZ/TractSeg)
- [`scilpy`](https://github.com/scilus/scilpy)

To build this Docker container, clone the repository and run the following command in the root directory:

```bash
DOCKER_BUILDKIT=1 sudo docker build -t beyondfa_baseline:v1.1.0
```

The Docker runs the code from `scripts/entrypoint.sh`.

## Running the Docker

Your Docker container should be able to read input data from `/input` and write output data to `/output`. Intermediate data should be written to `/tmp`. The input data will be a `.mha` file containing the diffusion MRI data with gradient table information contained in a `.json` file. The input file will be in `/input/images/dwi-4d-brain-mri/`, with gradient table information at `/input/dwi-4d-acquisition-metadata.json` Your Docker should read in data in the input directory and write a JSON list to the output directory with the same name as the input file.

See `scripts/convert_mha_to_nifti.py` and `scripts/convert_json_to_bvalbvec.py` for scripts to convert the `.mha` to `.nii.gz` and the `.json` to `.bval` and `.bvec` files.

To run this Docker:

```bash
input_dir=".../input_data"
output_dir=".../output_data"

mkdir -p $output_dir

DOCKER_NOOP_VOLUME="beyondfa_baseline-volume"
sudo docker volume create "$DOCKER_NOOP_VOLUME" > /dev/null
sudo docker run \
    -it \
    --platform linux/amd64 \
    --network none \
    --gpus all \
    --rm \
    --volume $input_dir:/input:ro \
    --volume $output_dir:/output \
    --volume "$DOCKER_NOOP_VOLUME":/tmp \
    beyondfa_baseline:v1.1
sudo docker volume rm "$DOCKER_NOOP_VOLUME" > /dev/null
```