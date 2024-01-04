# nf-humann
Nextflow workflow running the HUMAnN metagenomic analysis tool

Parameters:

- samplesheet: File listing input files (required)
  - Format: sample,fastq_1,fastq_2
- output: Location for output files (required)
- metaphlan_db: MetaPhlAn reference database (required)
- chocophlan_db: Chocoplan reference database (required)
- translated_search_db: Translated search database (required)
- input_format: Indicates the file format for all inputs (default: fastq.gz)
- container__humann: Docker container running HUMAnN
- container__metaphlan: Docker container running MetaPhlAn
- container__samtools: Docker container running SAMtools
- container__pandas: Docker container running Python/pandas
- cpus: Number of CPUs to allocate per analysis (default: 16)
- memory_gb: Amount of memory to allocate per analysis in GB (default: 128)
- prescreen_threshold: Minimum estimated genome coverage for inclusion in pangenome search (default: 0.5)
- nucleotide_identity_threshold: identity threshold for nuclotide alignments
- nucleotide_query_coverage_threshold: query coverage threshold for nucleotide alignments
- nucleotide_subject_coverage_threshold: subject coverage threshold for nucleotide alignments
- translated_identity_threshold: identity threshold for translated alignments
- translated_query_coverage_threshold: query coverage threshold for translated alignments
- translated_subject_coverage_threshold: subject coverage threshold for translated alignments