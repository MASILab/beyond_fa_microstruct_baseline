metrics=("fa")

for metric in "${metrics[@]}"; do
    echo "Building with $metric..."
    docker build -t beyondfa_baseline:$metric --build-arg metric=$metric .
done