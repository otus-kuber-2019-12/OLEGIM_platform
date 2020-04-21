cd ./src
for d in *; do
    cd "$(pwd)/$d";
    docker build  -t olegim89/$d:v0.0.1 .
    docker push olegim89/$d:v0.0.1
    cd ..;
done