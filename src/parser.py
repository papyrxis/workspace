#!/usr/bin/env python3
import yaml
import sys

def flatten_dict(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = f'{parent_key}{sep}{k}' if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        elif isinstance(v, list):
            items.append((new_key, ' '.join(str(x) for x in v)))
        elif v is None:
            items.append((new_key, ''))
        else:
            items.append((new_key, str(v)))
    return dict(items)

def main():
    if len(sys.argv) < 2:
        print("Usage: parser.py <yaml_file> [prefix]", file=sys.stderr)
        sys.exit(1)
    file = sys.argv[1]
    prefix = sys.argv[2] if len(sys.argv) > 2 else "CONFIG_"

    try:
        with open(file) as f:
            data = yaml.safe_load(f)
        if not data:
            sys.exit(0)
        flat = flatten_dict(data)
        for k, v in flat.items():
            v_safe = str(v).replace('"', '\\"').replace('`','\\`')
            print(f'{prefix}{k}="{v_safe}"')
    except Exception as e:
        print(f'# Error parsing YAML: {e}', file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
