"use strict";

const getConfig = require("vuepress-bar");
const barConfig = getConfig(`${__dirname}/..`);

module.exports = {
  title: "GitLab.com Runbooks",
  description: "GitLab.com Runbooks, for the stressed",
  base: "/gitlab-com/runbooks/",
  dest: "public",
  themeConfig: {
    repo: "https://gitlab.com/gitlab-com/runbooks",
    docsDir: "docs",
    editLinks: true,
    editLinkText: "Edit this page",
    nav: [
      { text: "Home", link: "/" },
      { text: "Useful Links", link: "/links/" }
    ],
    sidebar: barConfig.sidebar
  },
  markdown: {
    linkify: true,
    anchor: { permalink: true },
    toc: { includeLevel: [1, 2] },
    extendMarkdown: md => {
      md.use(require("markdown-it-task-lists"));
      md.use(require("markdown-it-mermaid").default);
    }
  },
  plugins: ["@vuepress/last-updated"]
};
