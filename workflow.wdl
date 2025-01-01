version 1.0

workflow getSNPdup_VCFs {

    meta {
    author: "Phuwanat Sakornsakolpat"
        email: "phuwanat.sak@mahidol.edu"
        description: "Filter on SNPs and check ID duplication from VCF"
    }

     input {
        Array[File] vcf_files
    }

    scatter(this_file in vcf_files) {
        call run_filtering { 
            input: vcf = this_file
        }
    }

    output {
        Array[File] filtered_vcf = run_filtering.out_file
        Array[File] filtered_tbi = run_filtering.out_file_tbi
    }

}

task run_filtering {
    input {
        File vcf
        Int memSizeGB = 8
        Int threadCount = 2
        Int diskSizeGB = 8*round(size(vcf, "GB")) + 20
    String out_name = basename(vcf, ".vcf.gz")
    }
    
    command <<<
    bcftools view -v snps ~{vcf} -Oz -o ~{out_name}.snps.vcf.gz
    tabix -p vcf ~{out_name}.snps.vcf.gz
    zcat ~{out_name}.snps.vcf.gz | grep -v '##' | cut -f 3 | sort | uniq -c > report.txt
    >>>

    output {
        File out_file = select_first(glob("*.snps.vcf.gz"))
        File out_file_tbi = select_first(glob("*.snps.vcf.gz.tbi"))
        File dup_report = select_first(glob("report.txt"))
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "quay.io/biocontainers/bcftools@sha256:f3a74a67de12dc22094e299fbb3bcd172eb81cc6d3e25f4b13762e8f9a9e80aa"   # digest: quay.io/biocontainers/bcftools:1.16--hfe4b78e_1
        preemptible: 1
    }

}
