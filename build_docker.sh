metrics=("fa" "md" "rd" "ad" "ga")

for metric in "${metrics[@]}"; do
    echo "Building with $metric..."
    DOCKER_BUILDKIT=1 docker build -t beyondfa_baseline:$metric --build-arg METRIC=$metric .
done