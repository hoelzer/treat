params.outdir = 'results'

/*
* MAPPING w/ HISAT2 and SAMTOOLS
* TODO: maybe not needed here, but in general generate a merged channel like this (untested): 
* set assembly_id, file(assembly), file(read) from assemblies_mapping.join(reads_ch)
*/
process HISAT2 {
  publishDir params.outdir, mode:'copy'

  input:
  set assembly_id, file(assembly)
  set read_id, file(reads)
  val threads

  output:
  set assembly_id, file("${assembly_id}.sorted.bam")
  
  shell:
  '''
  hisat2-build !{assembly} !{assembly_id} 
  hisat2 -x !{assembly_id} -U !{reads} -p !{threads} | samtools view -bS | samtools sort -T tmp --threads !{threads} > !{assembly_id}.sorted.bam
  ''' 
}


