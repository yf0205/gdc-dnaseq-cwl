#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ncigdc/bio-client:ecfb12c2f41276f29862c1603f806b5478f9845405c5e2af5c7c0538f93425d9
  - class: ResourceRequirement
    coresMin: 1
    coresMax: 1
    ramMin: 1000
    ramMax: 1000
    tmpdirMin: 1
    tmpdirMax: 1
    outdirMin: 1
    outdirMax: 1

inputs:
  - id: config-file
    type: File
    inputBinding:
      prefix: --config-file
      position: 0

  - id: upload
    type: string
    default: upload
    inputBinding:
      position: 1

  - id: upload-bucket
    type: string
    inputBinding:
      prefix: --upload-bucket
      position: 2

  - id: upload-key
    type: string
    inputBinding:
      prefix: --upload_key
      position: 3

  - id: uuid
    type: string
    inputBinding:
      prefix: --uuid
      position: 4

  - id: input
    type: File
    inputBinding:
      position: 99

outputs:
  - id: output
    type: File
    outputBinding:
      glob: "*_upload.json"
      
baseCommand: [/usr/local/bin/bio_client.py]
