local oidc = import 'oidc.libjsonnet';

{
  persistent: {
    'xpack.monitoring.history.duration': '40d',
    'xpack.security.authc.realms.oidc': {
      google: {
        order: 2,
        'rp.client_id': '96344303296-2emvujshc7s46tnqbvphbbvhu840ce9b.apps.googleusercontent.com',
        'rp.response_type': 'code',
        'rp.requested_scopes': ['openid', 'email'],
        'rp.redirect_uri': 'https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/api/security/oidc/callback',
        'op.issuer': 'https://accounts.google.com',
        'op.authorization_endpoint': 'https://accounts.google.com/o/oauth2/v2/auth',
        'op.token_endpoint': 'https://oauth2.googleapis.com/token',
        'op.userinfo_endpoint': 'https://openidconnect.googleapis.com/v1/userinfo',
        'op.jwkset_path': 'https://www.googleapis.com/oauth2/v3/certs',
        'claims.principal': 'email',
        'claim_patterns.principal': '^([^@]+)@gitlab\\.com$',
      },
    },
  },
}
