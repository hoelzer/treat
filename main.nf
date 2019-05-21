#!/usr/bin/env nextflow

/*
* TREAT WORKFLOW -- TanscRiptome EvaluATion
*
* Author: hoelzer.martin@gmail.com
*/

def helpMSG() {
    log.info """

    Usage:
    nextflow run hoelzer/treat --assemblies test_data/rna-spades.fasta --reads test_data/eco.fastq

    Mandatory:
    --assemblies    e.g.: 'trinity.fasta spades.fasta orp.fasta' or '*.fasta' or '*/*.fasta'
    --reads         e.g.: 'trinity.fastq' or '*.fastq' or '*/*.fastq'
    --reference     reference genome
    --annotation    annotation file in gtf format corresponding to the reference file

    Options
    --cpus                   max cores for local use [default $params.cpus]
    --mem                    max memory in GB for local use [default $params.mem]
    --output                 name of the result folder [default $params.output]

    -with-report rep.html    gives a detailed CPU and RAM usage report in rep.html

    """.stripIndent()
}

if (params.help) { exit 0, helpMSG() }
if (params.assemblies == '') {exit 1, "--assemblies is a required parameter"}

// file channels
assemblies_ch = Channel
              .fromPath(params.assemblies)
              .map { file -> tuple(file.simpleName, file) }
assemblies_ch.into { assemblies_mapping_ch; assemblies_report_ch }
assemblies_report_ch.subscribe { println "Got: ${it}" }

reads_ch = Channel
              .fromPath(params.reads)
              .map { file -> tuple(file.simpleName, file) }


/*
* MAPPING w/ HISAT2 and SAMTOOLS
* TODO: maybe not needed here, but in general generate a merged channel like this (untested): 
* set assembly_id, file(assembly), file(read) from assemblies_mapping.join(reads_ch)
*/
process hisat2 {
  // echo true

  input:
  set assembly_id, file(assembly) from assemblies_mapping_ch
  set read_id, file(reads) from reads_ch

  output:
  set assembly_id, file("${assembly_id}.sorted.bam") into mapping_counting_ch

  shell:
  '''
  hisat2-build !{assembly} !{assembly_id} 
  hisat2 -x !{assembly_id} -U !{reads} -p !{params.cpus} | samtools view -bS | samtools sort -T tmp --threads !{params.cpus} > !{assembly_id}.sorted.bam
  ''' 
}


