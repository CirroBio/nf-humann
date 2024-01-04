process renorm_table {
    container "${params.container__humann}"
    publishDir "${params.output}/${sample}/", mode: 'copy', overwrite: true

    input:
    tuple val(sample), path(input_tsv)

    output:
    path "${sample}${params.relab_suffix}"

    """#!/bin/bash
set -e

echo Computing normalized abundances
humann_renorm_table \
    --input "${input_tsv}" \
    --output "${sample}${params.relab_suffix}" \
    --units relab

echo Done
ls -lahtr
    """

}