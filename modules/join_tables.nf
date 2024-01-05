process join_tables {
    container "${params.container__humann}"
    publishDir "${params.output}", mode: 'copy', overwrite: true

    input:
    path "inputs/"

    output:
    path "${params.output_filename}"

    """#!/bin/bash
set -e

echo Joining tables
humann_join_tables \
    --input inputs \
    --output "${params.output_filename}" \
    --file_name "${params.join_name}"

echo Done
ls -lahtr
    """

}