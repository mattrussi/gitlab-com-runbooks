// Disk utilisation metrics are currently reporting incorrectly for
// HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10248
// as such, we only record this utilisation metric on IO subset of the fleet for now.

{
  diskPerformanceSensitiveServices:: ['patroni', 'gitaly', 'nfs'],
}
