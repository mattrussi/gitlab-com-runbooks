local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition({ tool:: 'cloudflare' });

{
  cloudflare(
    accountId='852e9d53d0f8adbd9205389356f2303d',
    zone='gitlab.com',
    host='gitlab.com'
  )::
    function(options)
      [
        toolingLinkDefinition({
          title: 'Cloudflare: ' + host,
          url: 'https://dash.cloudflare.com/%(accountId)s/%(zone)s/analytics/traffic?host=%(host)s&time-window=30' % {
            accountId: accountId,
            zone: zone,
            host: host,
          },
        }),
      ],
}
