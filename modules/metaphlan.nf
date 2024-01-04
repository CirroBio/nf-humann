// Import the process
include {
    metaphlan_paired;
    metaphlan_single;
    metaphlan_call;
    combine;
    concat_bwt;
    concat_sam;
    merge
} from './submodules/metaphlan-nf/modules/process' addParams(db: "${params.metaphlan_db}")

workflow metaphlan {
    take:
    samplesheet_single
    samplesheet_paired
    
    main:

    // Check for input parameter
    if (!params.metaphlan_db){
        error "Must provide parameter 'metaphlan_db'"
    }

    // Point to the reference database
    Channel
        .fromPath("${params.metaphlan_db}*")
        .ifEmpty { error "No database files found at ${params.metaphlan_db}*" }
        .toSortedList()
        .set {metaphlan_db}

    // Paired-end alignment
    metaphlan_paired(
        samplesheet_paired
            .map {
                row -> [
                    row.sample,
                    file(row.fastq_1, checkIfExists: true),
                    file(row.fastq_2, checkIfExists: true)
                ]
            },
        metaphlan_db
    )

    // Single-end
    metaphlan_single(
        samplesheet_single
            .map {
                row -> [
                    row.sample,
                    file(row.fastq_1, checkIfExists: true)
                ]
            },
        metaphlan_db
    )

    bwt_ch = metaphlan_paired.out.bwt
        .mix(metaphlan_single.out.bwt)

    sam_ch = metaphlan_paired.out.sam
        .mix(metaphlan_single.out.sam)

    // If there are any samples with multiple sets of read pairs,
    // concat those alignments into a single file
    concat_bwt(bwt_ch.groupTuple())
    concat_sam(sam_ch.groupTuple())

    // Run the metaphlan community profiling algorithm on the combined
    // set of (1) samples which only had a single pair of reads, and
    // (2) the merged alignments from samples with multiple pairs of reads
    metaphlan_call(
        concat_bwt.out,
        metaphlan_db
    )

    // Parse the sample name from the metaphlan output file
    metaphlan_call
        .out
        .metaphlan
        .map {
            it -> [it.name.replace(".metaphlan", ""), it]
        }
        .set {
            taxonomic_profile
        }

    // Combine the results
    combine(
        metaphlan_call.out.metaphlan.toSortedList()
    )

    // Merge tables using the metaphlan utility
    merge(
        metaphlan_call.out.metaphlan.toSortedList()
    )

    emit:
    taxonomic_profile
}