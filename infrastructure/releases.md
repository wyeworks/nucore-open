# Release process
In a regular release, there is first a release to Test and then one for Prod. The code in both releases is going to be the same.

1. Login to Docker Registry. Both `<USER>` and `<PASSWORD>` are in 1Password (name is Corum - Docker).
```
docker login -u <USER> -p <PASSWORD> umaitiscr.azurecr.io
```

2. Build a Docker image for the new changes. `<TAG>` is going to be the one you'll use for the repo. There isn't anything linking these two but it's good for keeping consistency.
```
docker build --target deploy -t umaitiscr.azurecr.io/corum/nucore-app:<TAG> --build-arg RAILS_SERVE_STATIC_FILES=true --build-arg RAILS_HOST=corum.umass.edu .
```
3. Push image to Azure
```
docker push umaitiscr.azurecr.io/corum/nucore-app:<TAG>
```
4. Release to test. This needs to be run from the [infra repo](https://github.com/UMass-CORUM/nucore-umass-deploy). Remember to update `<TAG>`.
```
nomad job run -var="image_id=<TAG>" nomad.d/corum-test.nomad.hcl
```
5. When it's time to, release to prod.
```
nomad job run -var="image_id=<TAG>" nomad.d/corum-prod.nomad.hcl
```

# Additional info
* There is also Dev env. For updating it, just run the command using `corum-dev.nomad.hcl`.
