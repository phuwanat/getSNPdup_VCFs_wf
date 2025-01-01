version 1.0

workflow getSNPdup_VCFs {

    meta {
    author: "Phuwanat Sakornsakolpat"
        email: "phuwanat.sak@mahidol.edu"
        description: "Filter on SNPs and check ID duplication from VCF"
    }

     input {
        File vcf_file
    }

    call run_filtering { 
            input: vcf = vcf_file
    }

    output {
        File snp_vcf = run_filtering.snp_vcf
        File snp_tbi = run_filtering.snp_tbi
        File snpdup_txt = run_filtering.snpdup_txt
        String snpdup_num = run_filtering.snpdup_num
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
    wc -l report.txt > reportnum.txt
    >>>

    output {
        File snp_vcf = select_first(glob("*.snps.vcf.gz"))
        File snp_tbi = select_first(glob("*.snps.vcf.gz.tbi"))
        File snpdup_txt = select_first(glob("report.txt"))
        String snpdup_num = read_string("reportnum.txt")
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "quay.io/biocontainers/bcftools@sha256:f3a74a67de12dc22094e299fbb3bcd172eb81cc6d3e25f4b13762e8f9a9e80aa"   # digest: quay.io/biocontainers/bcftools:1.16--hfe4b78e_1
        preemptible: 1
    }

}
