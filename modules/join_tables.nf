process join_tables {
    container "${params.container__humann}"
    publishDir "${params.output}", mode: 'copy', overwrite: true

    input:
    path "inputs/"

    output:
    path "${params.output_filename}"

    """#!/bin/bash
set -e

ls -lah inputs

# Remove the specified suffix from inputs
echo "Removing input file suffix '${params.remove_suffix}'"
for fp in inputs/*${params.remove_suffix}; do

    if [ -s "\$fp" ]; then
        mv "\$fp" "\${fp/${params.remove_suffix}/.tsv}"
    fi

done

ls -lah inputs

echo Joining tables
humann_join_tables \
    --input inputs \
    --output "${params.output_filename}"

echo Done
ls -lahtr
    """

}