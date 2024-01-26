{ pkgs }:
let
  # Calliope\ We'll just inline this for now, but we could put this into the jsonnet-tool repo
  jsonnet-tool = (pkgs.buildGoModule rec {
    pname = "jsonnet-tool";
    version = "1.9.1";
    src = pkgs.fetchFromGitLab {
      owner = "gitlab-com/gl-infra";
      repo  = "jsonnet-tool";
      rev   = "v${version}";
      sha256 = "sha256-zcBK+bxphhS9Fb7xluKIMZyWRLX4QfgzVAazxOo50nw=";
    };
    vendorSha256 = "sha256-7qdd9VtGPtPlmArWBYXC2eTAAaLM0xAXUxbt7NCyQVU=";
  });

  terraform = (pkgs.mkTerraform {
    version = "1.6.5";
    sha256 = "sha256-V5sI8xmGASBZrPFtsnnfMEHapjz4BH3hvl0+DGjUSxQ=";
    vendorSha256 = "sha256-OW/aS6aBoHABxfdjDxMJEdHwLuHHtPR2YVW4l0sHPjE=";
    patches = [ ./patches/provider-path-0_15.patch ];
  });

in pkgs.mkShell {
  name     = "runbooks";
  packages = with pkgs; [
    jsonnet-tool
    ruby_3_2
    go-jsonnet
    jsonnet-bundler
    prometheus-alertmanager
    prometheus
    gnumake
    yq-go
    kubeconform
    shfmt
    shellcheck
  ];
}
