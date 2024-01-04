include {
    renorm_table as renorm_genefamilies
} from "./renorm_table" addParams(
    output_suffix: "_2_genefamilies_relab.tsv"
)

include {
    renorm_table as renorm_pathabundance
} from "./renorm_table" addParams(
    output_suffix: "_4_pathabundance_relab.tsv"
)

include {
    join_tables as join_genefamilies
} from "./join_tables" addParams(
    output_filename: "humann_2_genefamilies.tsv",
    join_name: "genefamilies_relab"
)

include {
    join_tables as join_pathabundance
} from "./join_tables" addParams(
    output_filename: "humann_4_pathabundance.tsv",
    join_name: "pathabundance_relab"
)

process humann_call {
    container "${params.container__humann}"
    publishDir "${params.output}", mode: 'copy', overwrite: true

    // Resources used
    cpus "${params.cpus}"
    memory "${params.memory_gb}.GB"

    input:
    tuple val(sample), path("inputs/"), path(taxonomic_profile)
    path chocoplan_db
    path "translated_search_db/"

    output:
    tuple val(sample), path("${sample}/*"), emit: all
    tuple val(sample), path("${sample}/*_genefamilies.tsv"), emit: genefamilies
    tuple val(sample), path("${sample}/*_pathabundance.tsv"), emit: pathabundance

    """#!/bin/bash
set -e

echo "Unpacking the chocophlan database"
mkdir -p chocophlan_db
tar xzf "${chocoplan_db}" --directory chocophlan_db
ls -lahtr chocophlan_db/

echo "Setting up the reference database locations"
humann_config --update database_folders nucleotide "\$PWD/chocoplan_db"
# humann_config --update database_folders protein "\$PWD/\$translated_search_db"

# Check to see if there is more than one FASTQ input file
ls -lh inputs/*
if (( \$(ls inputs/* | wc -l) > 1 )); then
    echo "More than one input file detected - merging"
    cat inputs/* > INPUT.${params.input_format}
else
    echo "A single input file has been detected"
    ln -s inputs/* INPUT.${params.input_format}
fi

echo "Running humann --version"
humann --version

echo "Running humann"
humann \
    --input "INPUT.${params.input_format}" \
    --output "${sample}" \
    --threads ${task.cpus} \
    --taxonomic-profile "${taxonomic_profile}" \
    --input-format "${params.input_format}" \
    --prescreen-threshold "${params.prescreen_threshold}" \
    --nucleotide-identity-threshold "${params.nucleotide_identity_threshold}" \
    --nucleotide-query-coverage-threshold "${params.nucleotide_query_coverage_threshold}" \
    --nucleotide-subject-coverage-threshold "${params.nucleotide_subject_coverage_threshold}" \
    --translated-identity-threshold "${params.translated_identity_threshold}" \
    --translated-query-coverage-threshold "${params.translated_query_coverage_threshold}" \
    --translated-subject-coverage-threshold "${params.translated_subject_coverage_threshold}" \
    --remove-temp-output \
    --nucleotide-database "\$PWD/chocophlan_db/" \
    --protein-database "\$PWD/translated_search_db/"

echo Done

echo Removing local chocophlan database
rm -r chocoplan_db
echo Done

ls -lahtr
ls -lahtr "${sample}/"
    """

}

workflow humann {

    take:
    samplesheet_single
    samplesheet_paired
    metaphlan_out

    main:

    // Check for input parameters
    if (!params.chocophlan_db){
        error "Must provide parameter 'chocophlan_db'"
    }

    if (!params.translated_search_db){
        error "Must provide parameter 'translated_search_db'"
    }

    // Point to reference databases
    chocophlan_db = file(
        params.chocophlan_db,
        checkIfExists: true
    )

    translated_search_db = file(
        params.translated_search_db,
        checkIfExists: true
    )

    // Get all of the FASTQ files for each sample
    samplesheet_single
        .map { [it.sample, file(it.fastq_1)] }
        .mix (
            samplesheet_paired
                .map {
                    [it.sample, file(it.fastq_1)]
                }
        )
        .mix (
            samplesheet_paired
                .map {
                    [it.sample, file(it.fastq_2)]
                }
        )
        .groupTuple()
        .set { fastq_ch }

    // Join the FASTQ files with the metaphlan output
    fastq_ch
        .join(metaphlan_out)
        .set { input_ch }

    // Run HUMAnN
    humann_call(input_ch, chocophlan_db, translated_search_db)

    // // Renormalize the genefamilies and pathway abundances
    renorm_genefamilies(humann_call.out.genefamilies)
    renorm_pathabundance(humann_call.out.pathabundance)

    // Join the genefamilies and pathway abundances
    join_genefamilies(renorm_genefamilies.out.toSortedList())
    join_pathabundance(renorm_pathabundance.out.toSortedList())

}