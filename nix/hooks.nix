{ ... }:
{
  perSystem =
    { config, ... }:
    {
      pre-commit.settings = {
        hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };

          clippy.enable = true;
          check-merge-conflict.enable = true;
          check-added-large-files.enable = true;
        };
      };
    };
}
