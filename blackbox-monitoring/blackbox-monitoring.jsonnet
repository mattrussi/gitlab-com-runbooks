local defaults = {
  pagespeed: false,
  sitespeed: [],
};

local pagespeed = {
  // pagespeed is used to generate Google Pagespeed metrics
  pagespeed: true
};

local monitoredUrls = {
  # These URLs are taken from https://yukari.sr.ht/forgeperf.html
  "https://gitlab.com/ddevault/scdoc": pagespeed,
  "https://gitlab.com/ddevault/scdoc/-/tree/master/src": pagespeed,
  "https://gitlab.com/ddevault/linux/-/tree/master/arch/arm/boot/dts": pagespeed,
  "https://gitlab.com/ddevault/scdoc/-/commits/master": pagespeed,
  "https://gitlab.com/ddevault/linux/-/commits/master": pagespeed,
  "https://gitlab.com/ddevault/scdoc/-/commit/baaebab77db8123ee97a1c4c6a25c0873abf25e7": pagespeed,
  "https://gitlab.com/ddevault/scdoc/-/blob/master/src/main.c": pagespeed,
  "https://gitlab.com/ddevault/linux/-/blob/master/MAINTAINERS": pagespeed,
  "https://gitlab.com/ddevault/scdoc/-/blame/master/src/main.c": pagespeed,
  "https://gitlab.com/ddevault/linux/-/blame/master/MAINTAINERS": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/issues": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/issues?scope=all&utf8=%E2%9C%93&state=opened&search=kernel": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/issues/153": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/merge_requests": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/merge_requests/1002": pagespeed,
  "https://gitlab.com/postmarketOS/pmaports/-/merge_requests/1036/diffs": pagespeed,

  "https://gitlab.com/-/ide/project/gitlab-org/gitlab/edit/master/-/": {
    sitespeed: ['desktop/loggedinurls/desktop'],
  },

  "https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/environments/269942/metrics": {
    sitespeed: ['desktop/loggedinurls/desktop'],
  },

  "https://gitlab.com/explore": {
    sitespeed: [
      'desktop/urls/desktop',
      'emulatedMobile/urls/emulatedMobile',
    ],
  },

  "https://gitlab.com/gitlab-org/gitlab": {
    sitespeed: [
      'desktop/urls/desktop',
      'emulatedMobile/urls/emulatedMobile',
    ],
  },

  "https://gitlab.com/gitlab-org/gitlab/tree/master": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/javascripts/main.js": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12419": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/9546": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9546/diffs": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab/issues": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/sytses/test-2/issues/1": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/issues/1": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/issues/34225": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/issues/4058": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab/boards": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab/pipelines": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gitlab-org/gitlab-foss/pipelines/9360254": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/snippets/1662597": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/groups/gitlab-org/-/epics": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/groups/gitlab-org/-/epics/2089": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/groups/gitlab-org/-/roadmap": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/groups/gitlab-org/-/milestones/41": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://github.com/gnachman/iTerm2/tree/master/tools": {
    sitespeed: ['desktop/urls/desktop'],
  },
  "https://gitlab.com/gnachman/iterm2/-/tree/master/tools": {
    sitespeed: ['desktop/urls/desktop'],
  },

  "https://dev.gitlab.org/": {
    sitespeed: ['dev/urls/desktop'],
  },
  "https://dev.gitlab.org/explore/projects": {
    sitespeed: ['dev/urls/desktop'],
  },
  "https://dev.gitlab.org/cookbooks/runbooks": {
    sitespeed: ['dev/urls/desktop'],
  },
  "https://dev.gitlab.org/cookbooks/runbooks/commits/master": {
    sitespeed: ['dev/urls/desktop'],
  },
  "https://dev.gitlab.org/cookbooks/runbooks/blob/master/img/ci-runner-manager-errors.png": {
    sitespeed: ['dev/urls/desktop'],
  },

  "https://gitter.im/?redirect=no": {
    sitespeed: ['gitter/urls/desktop'],
  },

  "https://gitter.im/gitterHQ/sandbox": {
    sitespeed: ['gitter/urls/desktop'],
  },

  "https://about.gitlab.com/": {
    sitespeed: ['www-about/urls/desktop'],
  },

  "https://about.gitlab.com/stages-devops-lifecycle/": {
    sitespeed: ['www-about/urls/desktop'],
  },

  "https://about.gitlab.com/handbook/": {
    sitespeed: ['www-about/urls/desktop'],
  },

  "https://about.gitlab.com/company/team/": {
    sitespeed: ['www-about/urls/desktop'],
  }
};

local listUrls(predicate) =
  local allUrls = std.sort(std.objectFields(monitoredUrls));
  std.filter(function(url) predicate(defaults + monitoredUrls[url]), allUrls);

local siteSpeedUrls(file) =
  listUrls(function(c) std.member(c.sitespeed, file));

local textFile(urls) =
  std.join('\n', urls);

{
  'pagespeed.txt': textFile(listUrls(function(x) x.pagespeed)),
  'sitespeed/desktop/urls/desktop.txt': textFile(siteSpeedUrls('desktop/urls/desktop')),
  'sitespeed/desktop/loggedinurls/desktop.txt': textFile(siteSpeedUrls('desktop/loggedinurls/desktop')),
  'sitespeed/dev/urls/desktop.txt': textFile(siteSpeedUrls('dev/urls/desktop')),
  'sitespeed/emulatedMobile/urls/emulatedMobile.txt': textFile(siteSpeedUrls('emulatedMobile/urls/emulatedMobile')),
  'sitespeed/gitter/urls/desktop.txt': textFile(siteSpeedUrls('gitter/urls/desktop')),
  'sitespeed/www-about/urls/desktop.txt': textFile(siteSpeedUrls('www-about/urls/desktop')),
}
