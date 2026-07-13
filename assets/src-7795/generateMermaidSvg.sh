#!/bin/bash

# npm install -g @mermaid-js/mermaid-cli
# cd assets/src-7795
# chmod +x generateMermaidSvg.sh
# ./generateMermaidSvg.sh

mmdc -i ./eoa_example.mmd -o ./eoa_example.svg
mmdc -i ./sc_example.mmd -o ./sc_example.svg