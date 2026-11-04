# Legacy shell integration

The legacy shell entry points remain for older document generators, but their
configuration boundary must follow the same rules as the new Python package.

- src/parser.py uses yaml.safe_load and emits base64-encoded key/value records.
- src/loader.sh validates variable names and decodes values. It never uses eval.
- src/sync.sh calls load_from_config before resolving project type, overrides and
  the explicitly configured component list.
- PyYAML is required. There is no sed/awk fallback that turns YAML into executable
  shell assignments.

For example, a project can request the legacy publication style component:

~~~yaml
project:
  type: article

components:
  - colors
  - layout
  - paper-styles
  - bibliography
~~~

The list is preserved in CONFIG_components, and sync copies the corresponding
component from common/components into .pxis/components before generating the
preset. Project-specific overrides continue to take precedence over the
Workspace copy.
