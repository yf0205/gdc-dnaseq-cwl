#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

requirements:
 - class: InlineJavascriptRequirement
 - class: StepInputExpressionRequirement
 - class: SubworkflowFeatureRequirement

inputs:
  - id: alignment_last_step
    type: string
  - id: aws_config
    type: File
  - id: aws_shared_credentials
    type: File
  - id: bam_signpost_json
    type: File
  - id: db_snp_signpost_id
    type: string
  - id: endpoint_json
    type: File
  - id: load_bucket
    type: string
  - id: load_s3cfg_section
    type: string
  - id: reference_fa_signpost_id
    type: string
  - id: signpost_base_url
    type: string
  - id: uuid
    type: string

outputs:
  - id: load_sqlite_output
    type: File
    outputSource: load_sqlite/output

steps:
  - id: extract_bam
    run: ../../tools/aws_s3_get_signpost.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: signpost_json
        source: bam_signpost_json
      - id: endpoint_json
        source: endpoint_json
    out:
      - id: output

  - id: extract_db_snp_signpost
    run: ../../tools/get_signpost_json.cwl
    in:
      - id: signpost_id
        source: db_snp_signpost_id
      - id: base_url
        source: signpost_base_url
    out:
      - id: output

  - id: extract_db_snp
    run: ../../tools/aws_s3_get_signpost.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: signpost_json
        source: extract_db_snp_signpost/output
      - id: endpoint_json
        source: endpoint_json
    out:
      - id: output

  - id: extract_ref_fa_signpost
    run: ../../tools/get_signpost_json.cwl
    in:
      - id: signpost_id
        source: reference_fa_signpost_id
      - id: base_url
        source: signpost_base_url
    out:
      - id: output

  - id: extract_ref_fa
    run: ../../tools/aws_s3_get_signpost.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: signpost_json
        source: extract_ref_fa_signpost/output
      - id: endpoint_json
        source: endpoint_json
    out:
      - id: output

  - id: transform
    run: md_workflow.cwl
    in:
      - id: alignment_last_step
        source: alignment_last_step
      - id: bam_path
        source: extract_bam/output
      - id: fasta_path
        source: extract_ref_fa/output
      - id: load_bucket
        source: load_bucket
      - id: uuid
        source: uuid
      - id: vcf_path
        source: extract_db_snp/output
    out:
      - id: picard_markduplicates_output_bam
      - id: merge_all_sqlite_destination_sqlite

  - id: load_bam
    run: ../../tools/aws_s3_put.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: endpoint_json
        source: endpoint_json
      - id: input
        source: transform/picard_markduplicates_output_bam
      - id: s3cfg_section
        source: load_s3cfg_section
      - id: s3uri
        source: load_bucket
        valueFrom: |
          ${
          
            function endsWith(str, suffix) {
              return str.indexOf(suffix, str.length - suffix.length) !== -1;
            }
          
            if ( endsWith(self, '/') ) {
              return self + inputs.uuid + '/';
            }
            else {
              return self + '/' + inputs.uuid + '/';
            }
          
          }
      - id: uuid
        source: uuid
        valueFrom: $(null)
    out:
      - id: output

  - id: load_bai
    run: ../../tools/aws_s3_put.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: endpoint_json
        source: endpoint_json
      - id: input
        source: transform/picard_markduplicates_output_bam
        valueFrom: $(self.secondaryFiles[0])
      - id: s3cfg_section
        source: load_s3cfg_section
      - id: s3uri
        source: load_bucket
        valueFrom: |
          ${
          
            function endsWith(str, suffix) {
              return str.indexOf(suffix, str.length - suffix.length) !== -1;
            }
          
            if ( endsWith(self, '/') ) {
              return self + inputs.uuid + '/';
            }
            else {
              return self + '/' + inputs.uuid + '/';
            }
          
          }
      - id: uuid
        source: uuid
        valueFrom: $(null)
    out:
      - id: output

  - id: load_sqlite
    run: ../../tools/aws_s3_put.cwl
    in:
      - id: aws_config
        source: aws_config
      - id: aws_shared_credentials
        source: aws_shared_credentials
      - id: endpoint_json
        source: endpoint_json
      - id: input
        source: transform/merge_all_sqlite_destination_sqlite
      - id: s3cfg_section
        source: load_s3cfg_section
      - id: s3uri
        source: load_bucket
        valueFrom: |
          ${
          
            function endsWith(str, suffix) {
              return str.indexOf(suffix, str.length - suffix.length) !== -1;
            }
          
            if ( endsWith(self, '/') ) {
              return self + inputs.uuid + '/';
            }
            else {
              return self + '/' + inputs.uuid + '/';
            }
          
          }
      - id: uuid
        source: uuid
        valueFrom: $(null)
    out:
      - id: output
