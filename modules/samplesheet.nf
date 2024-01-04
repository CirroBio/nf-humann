workflow samplesheet {

    main:

    // Check for input parameters
    if (!params.samplesheet){
        error "Must provide parameter 'samplesheet'"
    }

    Channel
        .fromPath(
            "${params.samplesheet}",
            checkIfExists: true,
            glob: false
        )
        .splitCsv(
            header: true
        )
        .branch {
            single: it.fastq_2 == null || it.fastq_2 == ""
            paired: true
        }
        .set {
            samplesheet
        }

    emit:
    single = samplesheet.single
    paired = samplesheet.paired

}