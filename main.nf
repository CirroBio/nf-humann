#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

include { samplesheet } from './modules/samplesheet'
include { metaphlan } from './modules/metaphlan'
include { humann } from './modules/humann'

workflow {

    log.info"""
CirroBio/nf-humann

Workflow running the HUMAnN metagenomic analysis tool.
    Docs: https://github.com/biobakery/humann

Parameters:
    samplesheet: File listing input files (required)
        Format: sample,fastq_1,fastq_2
        Provided: ${params.samplesheet}

    output: Location for output files (required)
        Provided: ${params.output}

    metaphlan_db: MetaPhlAn reference database (required)
        Provided: ${params.metaphlan_db}

    chocophlan_db: Chocoplan reference database (required)
        Provided: ${params.chocophlan_db}

    translated_search_db: Translated search database (required)
        Provided: ${params.translated_search_db}

    input_format: Indicates the file format for all inputs (default: fastq.gz)
        Provided: ${params.input_format}

    container__humann: Docker container running HUMAnN
        Provided: ${params.container__humann}

    container__metaphlan: Docker container running MetaPhlAn
        Provided: ${params.container__metaphlan}

    container__samtools: Docker container running SAMtools
        Provided: ${params.container__samtools}

    container__pandas: Docker container running Python/pandas
        Provided: ${params.container__pandas}

    cpus: Number of CPUs to allocate per analysis (default: 16)
        Provided: ${params.cpus}

    memory_gb: Amount of memory to allocate per analysis in GB (default: 128)
        Provided: ${params.memory_gb}

    prescreen_threshold: Minimum estimated genome coverage for inclusion in pangenome search (default: 0.5)
        Provided: ${params.prescreen_threshold}

    nucleotide_identity_threshold: identity threshold for nuclotide alignments
        Provided: ${params.nucleotide_identity_threshold}

    nucleotide_query_coverage_threshold: query coverage threshold for nucleotide alignments
        Provided: ${params.nucleotide_query_coverage_threshold}

    nucleotide_subject_coverage_threshold: subject coverage threshold for nucleotide alignments
        Provided: ${params.nucleotide_subject_coverage_threshold}

    translated_identity_threshold: identity threshold for translated alignments
        Provided: ${params.translated_identity_threshold}

    translated_query_coverage_threshold: query coverage threshold for translated alignments
        Provided: ${params.translated_query_coverage_threshold}

    translated_subject_coverage_threshold: subject coverage threshold for translated alignments
        Provided: ${params.translated_subject_coverage_threshold}
    """

    // Check for input parameters
    if (!params.output){
        error "Must provide parameter 'output'"
    }

    // Parse the samplesheet
    samplesheet()

    // Run MetaPhlan on the input reads
    metaphlan(
        samplesheet.out.single,
        samplesheet.out.paired,
    )

    // Run HUMAnN on the input reads, combined with the
    // outputs from MetaPhlAn
    humann(
        samplesheet.out.single,
        samplesheet.out.paired,
        metaphlan.out
    )

}