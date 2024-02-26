// include { prepare_databases } from './modules/from_wf/databases'
include { prepare_input } from './modules/prepare'

process emu_process {
    label "Emu"
    cpus params.threads
    publishDir (
        params.out_dir,
        mode: "copy"
    )
    input:
        path fq
        val emudb
    output:
        path "dir_emuoutput/*_rel-abundance.tsv" , emit: tsv
        path "dir_emuoutput/*_emu_alignments.sam"
    script:
    println "${fq}"
    """
    emu abundance --type map-ont --threads "${task.cpus}" \
    --db "${emudb}" \
    --output-dir dir_emuoutput \
    --keep-counts --keep-files \
    "${fq}"
    """
}
// due to combine process need all abundance file, must after emu process( or figure out how to executed all fq once a process )
process emu_combine {
    label "Emu"
    cpus params.threads
    storeDir params.store_dir
    input:
        path emu_output
    output:
        path "dir_abundance" , emit: dir_abundance
        path "dir_abundance/emu-combined-species.tsv" , emit: combined_tsv
    script:
    """
    mkdir dir_abundance
    echo ${emu_output}
    mv ${emu_output} dir_abundance
    emu combine-outputs dir_abundance species
    """
}
process parse_header{
    label "wfmetagenomics"
    storeDir params.store_dir
    input:
        path combined_tsv
    output:
        path "lefse_input" , emit: lefse_input
        path "krona_dir" 
        path "krona_dir/*" , emit: krona_files
        path "R_TSE/TSErow" , emit: TSErow
        path "R_TSE/TSEassay" , emit: TSEassay
    script:
    println "${combined_tsv}"
    """
    mkdir krona_dir
    mkdir R_TSE
    parse_input.py -a ${combined_tsv} -o1 lefse_input -o2 krona_dir -o3 R_TSE/TSErow -o4 R_TSE/TSEassay
    """
}
process lefse_process{
    label "LEfSe"
    publishDir (
        params.out_dir,
        mode: "copy"
    )
    input:
        path lefse_input
    output:
        path lefse
        path "lefse/lefse.png"
        path "lefse/lefse.clad.png"
    script:
    """
    mkdir lefse
    format_input.py ${lefse_input} lefse_input.in  -c 2 -s -1  -u 1 -o 1000000 &&
    run_lefse.py -l 4 lefse_input.in lefse_input.res &&
    plot_res.py --dpi 300 lefse_input.res lefse.png &&
    plot_cladogram.py --dpi 300 --format png lefse_input.res lefse.clad.png
    mv lefse.png lefse.clad.png lefse
    """
}
process krona_process{
    label "krona"
    publishDir (
        params.out_dir,
        mode: "copy"
    )
    input:
        path krona_files
    output:
        path "krona.html"
    script:
    """
    ktImportText ${krona_files} -o krona.html
    """
}
process ch2_vis{
    label "Rstudio"
    storeDir params.store_dir
    input:
        path TSEassay
        path TSErow
        path TSEcol
        path lefse_input
    output:
        path "ch2/*"
    script:
    """
    mkdir ch2
    ch2.R -f1 ${TSEassay} -f2 ${TSErow} -f3 ${TSEcol} -d ch2/ -l ${lefse_input}
    """
}
process ch3_vis{
    label "Rstudio"
    storeDir params.store_dir
    input:
        path TSEassay
        path TSErow
        path TSEcol
    output:
        path "ch3/*"
    script:
    """
    mkdir ch3
    ch3.R -f1 ${TSEassay} -f2 ${TSErow} -f3 ${TSEcol} -d ch3/
    """
}

process ch4_vis{
    label "Rstudio"
    storeDir params.store_dir
    input:
        path TSEassay
        path TSErow
        path TSEcol
    output:
        path "ch4/*"
    script:
    """
    mkdir ch4
    ch4.R -f1 ${TSEassay} -f2 ${TSErow} -f3 ${TSEcol} -d ch4/
    """
}

workflow {
    // input = prepare_input(params.fqFolder,params.emu_db)
    // emu_process = emu_process(input.fq, input.emudb)
    // emu_combine = emu_combine(emu_process.tsv.collect())
    // parse_header = parse_header(emu_combine.combined_tsv)
    parse_header = parse_header(params.combined_tsv)
    ch2_vis(
        parse_header.TSEassay, 
        parse_header.TSErow, 
        params.TSEcol,
        parse_header.lefse_input)
    ch3_vis(
    parse_header.TSEassay, 
    parse_header.TSErow, 
    params.TSEcol)
    ch4_vis(
    parse_header.TSEassay, 
    parse_header.TSErow, 
    params.TSEcol)
    // lefse_process(parse_header.lefse_input)
    // lefse_process(params.lefse_input)
    // krona_process(parse_header.krona_files.collect())
}
