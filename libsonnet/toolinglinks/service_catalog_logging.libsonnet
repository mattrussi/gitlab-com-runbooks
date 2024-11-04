local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition({ type:: 'log' });
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';

{
  serviceCatalogLogging(type)::
    local serviceCatalogEntry = serviceCatalog.lookupService(type);

    function(options)
      (
        if serviceCatalogEntry != null
        then [
          toolingLinkDefinition({
            title: log.name,
            url: log.permalink,
          })
          for log in std.get(serviceCatalogEntry.technical, 'logging', [])
        ]
        else []
      ),
}
