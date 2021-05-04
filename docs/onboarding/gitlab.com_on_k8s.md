# Gitlab.com on K8S

A collection of info about gitlab.com on K8S

### Which workloads are actually running on k8s?

- Production:
  - Regional
    ```
      gitlab-kas
      gitlab-mailroom                     
      gitlab-sidekiq-catchall-v1
      gitlab-sidekiq-database-throttled-v1
      gitlab-sidekiq-elasticsearch-v1     
      gitlab-sidekiq-gitaly-throttled-v1
      gitlab-sidekiq-low-urgency-cpu-bound-v1
      gitlab-sidekiq-memory-bound-v1      
      gitlab-sidekiq-urgent-cpu-bound-v1
      gitlab-sidekiq-urgent-other-v1
  - Zonal
    ```
       gitlab-gitlab-shell         
       gitlab-registry
       gitlab-webservice-git       
       gitlab-webservice-websockets

- Staging:
  - Regional:
    ```
       Production:Regional
       gitlab-nginx-ingress-controller
       gitlab-nginx-ingress-default-backend
  - Zonal:
    ```
      Production:Zonal
       gitlab-nginx-ingress-controller
       gitlab-nginx-ingress-default-backend
       gitlab-webservice-api

### Image building

- Docker images for each component: https://gitlab.com/gitlab-org/build/CNG
  - Example: gitlab-shell Dockerfile: https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitlab-shell/Dockerfile
- Somethings that happen at the build pipeline of build/CNG:
  - https://gitlab.com/gitlab-org/build/CNG/-/blob/master/.gitlab-ci.yml#L907
  - Update deps: gitlab-org/gitlab-omnibus-builder/ruby_docker
  - Compile assets: build-scripts/build.sh
  - Danger review: gitlab-org/gitlab-build-images
- The bigger picture, example pipeline: https://gitlab.com/gitlab-org/build/CNG/-/pipelines/281835958

### Deployment pipeline to k8s

1. This is a rabbit hole.
1. There's a full team maintaing (Delivery) this, thankfully.
1. This must be where the charts are generated: https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/
1. Auto Deploy for details on how the pipeline is triggered: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com#auto-deploy
1. The Deployer, pipeline example: https://ops.gitlab.net/gitlab-com/gl-infra/deployer/-/pipelines/516853
   - This triggers a k8s-workloads pipeline: https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/pipelines/517366

### Regional vs Zonal clusters, node pools, taints

- Resources in a region are available to all zones.
   - Are Pods that are assigned to a Region automatically deployed to all Zones in a Region, or is it manually specified somewhere?
- Looks like our redundancy is zone-based.
- Zonal Node pools: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-zonal.tf#L114
- Regional Node pools: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-regional.tf#L161
- We don’t use taints, epic to implement them: https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/393

### Resources, requests, limits (WIP)

- Looks like `git-https` has a higher node count limit: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-zonal.tf#L52
- Default node count is `20`: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-regional.tf#L164

### Low-level: How do resource limits translate to kernel concepts like cgroups and namespaces? (WIP)
