#!/bin/bash

# Current Version: 1.2.9 (已修改数据源并添加统计和路径修正)

## How to get and use?
# git clone "https://github.com/jqyisbest/GFWList2AGH.git" && cd GFWList2AGH && bash ./source/release.sh

## Function
# Get Data
function GetData() {
    # Array of URLs for Chinese accelerated domains (direct access) - 已更新数据源
    cnacc_domain=(
        "https://raw.githubusercontent.com/jqyisbest/CustomDiversionRules/refs/heads/main/rules/cn/cn_domain_list.txt"
    )
    # Array of URLs for trusted Chinese domains (DNSMasq format)
    cnacc_trusted=(
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf"
    )

    # Array of URLs for GFW lists (plain text domains) - 已更新数据源
    gfwlist_domain=(
        "https://raw.githubusercontent.com/jqyisbest/CustomDiversionRules/refs/heads/main/rules/gfw/gfw_domain_list.txt"
    )
    # Array of URLs for custom modification data for this script
    gfwlist2agh_modify=(
        "https://raw.githubusercontent.com/jqyisbest/GFWList2AGH/source/data/data_modify.txt"
    )

    # Remove any existing temporary files/directories and create a new Temp directory
    echo "正在清理并创建临时目录 ./Temp..."
    rm -rf ./Temp && mkdir -p ./Temp

    # Download and process cnacc_domain lists
    echo "正在下载 CN 域名列表..."
    for cnacc_domain_task in "${!cnacc_domain[@]}"; do
        curl -s --connect-timeout 15 "${cnacc_domain[$cnacc_domain_task]}" | sed "s/^\.//g" >> ./Temp/cnacc_domain.tmp
    done
    echo "CN 域名列表下载完成。"

    # Download cnacc_trusted lists
    echo "正在下载受信任 CN 域名列表..."
    for cnacc_trusted_task in "${!cnacc_trusted[@]}"; do
        curl -s --connect-timeout 15 "${cnacc_trusted[$cnacc_trusted_task]}" >> ./Temp/cnacc_trusted.tmp
    done
    echo "受信任 CN 域名列表下载完成。"

    # Download and process gfwlist_domain lists
    echo "正在下载 GFW 域名列表..."
    for gfwlist_domain_task in "${!gfwlist_domain[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_domain[$gfwlist_domain_task]}" | sed "s/^\.//g" >> ./Temp/gfwlist_domain.tmp
    done
    echo "GFW 域名列表下载完成。"

    # Download gfwlist2agh_modify list
    echo "正在下载自定义修改列表..."
    for gfwlist2agh_modify_task in "${!gfwlist2agh_modify[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist2agh_modify[$gfwlist2agh_modify_task]}" >> ./Temp/gfwlist2agh_modify.tmp
    done
    echo "自定义修改列表下载完成。"
}

# Analyse Data
function AnalyseData() {
    echo "开始分析数据..."
    # Define domain regex patterns
    domain_regex="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$" 
    lite_domain_regex="^([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"

    # Process gfwlist2agh_modify.tmp to extract various modification rules
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\@\%\@\)\|\(\@\%\!\)\|\(\!\&\@\)\|\(\@\@\@\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./Temp/cnacc_addition.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\!\)\|\(\@\&\!\)\|\(\!\%\@\)\|\(\!\!\!\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./Temp/cnacc_subtraction.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\%\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/cnacc_exclusion.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\%\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/lite_cnacc_exclusion.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/cnacc_keyword.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/lite_cnacc_keyword.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\@\&\@\)\|\(\@\&\!\)\|\(\!\%\@\)\|\(\@\@\@\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./Temp/gfwlist_addition.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\!\)\|\(\@\%\!\)\|\(\!\&\@\)\|\(\!\!\!\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./Temp/gfwlist_subtraction.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\&\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/gfwlist_exclusion.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\&\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/lite_gfwlist_exclusion.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/gfwlist_keyword.tmp"
    cat "./Temp/gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./Temp/lite_gfwlist_keyword.tmp"
    
    cat "./Temp/cnacc_addition.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./Temp/lite_cnacc_addition.tmp"
    cat "./Temp/gfwlist_addition.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./Temp/lite_gfwlist_addition.tmp"
    
    cat "./Temp/cnacc_trusted.tmp" | sed "s/\/114\.114\.114\.114//g;s/server\=\///g" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./Temp/cnacc_trust.tmp"
    cat "./Temp/cnacc_trust.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./Temp/lite_cnacc_trust.tmp"
    
    cat "./Temp/cnacc_domain.tmp" | sed "s/domain\://g;s/full\://g" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./Temp/cnacc_checklist.tmp"
    cat "./Temp/gfwlist_domain.tmp" | sed "s/domain\://g;s/full\://g;s/http\:\/\///g;s/https\:\/\///g" | tr -d "|" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./Temp/gfwlist_checklist.tmp"
    
    cat "./Temp/cnacc_checklist.tmp" | rev | cut -d "." -f 1,2 | rev | sort | uniq > "./Temp/lite_cnacc_checklist.tmp"
    cat "./Temp/gfwlist_checklist.tmp" | rev | cut -d "." -f 1,2 | rev | sort | uniq > "./Temp/lite_gfwlist_checklist.tmp"
    
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/cnacc_checklist.tmp" "./Temp/gfwlist_checklist.tmp" > "./Temp/gfwlist_raw.tmp"

    awk_output_cnacc_raw=$(awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/gfwlist_checklist.tmp" "./Temp/cnacc_checklist.tmp")
    cnacc_excl_pats=$(cat "./Temp/cnacc_exclusion.tmp")
    cnacc_key_pats=$(cat "./Temp/cnacc_keyword.tmp")
    final_grep_pattern_cnacc=""
    if [ -n "$cnacc_excl_pats" ]; then final_grep_pattern_cnacc="(\\.(${cnacc_excl_pats})$)|(^(${cnacc_excl_pats})$)"; fi
    if [ -n "$cnacc_key_pats" ]; then
        if [ -n "$final_grep_pattern_cnacc" ]; then final_grep_pattern_cnacc="${final_grep_pattern_cnacc}|(${cnacc_key_pats})"; else final_grep_pattern_cnacc="(${cnacc_key_pats})"; fi
    fi
    if [ -n "$final_grep_pattern_cnacc" ]; then printf "%s\n" "$awk_output_cnacc_raw" | grep -Ev "$final_grep_pattern_cnacc" > "./Temp/cnacc_raw.tmp"; else printf "%s\n" "$awk_output_cnacc_raw" > "./Temp/cnacc_raw.tmp"; fi

    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/lite_cnacc_checklist.tmp" "./Temp/lite_gfwlist_checklist.tmp" > "./Temp/lite_gfwlist_raw.tmp"
    
    awk_output_lite_cnacc_raw=$(awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/lite_gfwlist_checklist.tmp" "./Temp/lite_cnacc_checklist.tmp")
    lite_cnacc_excl_pats=$(cat "./Temp/lite_cnacc_exclusion.tmp")
    lite_cnacc_key_pats=$(cat "./Temp/lite_cnacc_keyword.tmp")
    final_grep_pattern_lite_cnacc=""
    if [ -n "$lite_cnacc_excl_pats" ]; then final_grep_pattern_lite_cnacc="(\\.(${lite_cnacc_excl_pats})$)|(^(${lite_cnacc_excl_pats})$)"; fi
    if [ -n "$lite_cnacc_key_pats" ]; then
        if [ -n "$final_grep_pattern_lite_cnacc" ]; then final_grep_pattern_lite_cnacc="${final_grep_pattern_lite_cnacc}|(${lite_cnacc_key_pats})"; else final_grep_pattern_lite_cnacc="(${lite_cnacc_key_pats})"; fi
    fi
    if [ -n "$final_grep_pattern_lite_cnacc" ]; then printf "%s\n" "$awk_output_lite_cnacc_raw" | grep -Ev "$final_grep_pattern_lite_cnacc" > "./Temp/lite_cnacc_raw.tmp"; else printf "%s\n" "$awk_output_lite_cnacc_raw" > "./Temp/lite_cnacc_raw.tmp"; fi

    awk_output_gfwlist_raw=$(awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/cnacc_trust.tmp" "./Temp/gfwlist_raw.tmp")
    gfwlist_excl_pats=$(cat "./Temp/gfwlist_exclusion.tmp")
    gfwlist_key_pats=$(cat "./Temp/gfwlist_keyword.tmp")
    final_grep_pattern_gfwlist=""
    if [ -n "$gfwlist_excl_pats" ]; then final_grep_pattern_gfwlist="(\\.(${gfwlist_excl_pats})$)|(^(${gfwlist_excl_pats})$)"; fi
    if [ -n "$gfwlist_key_pats" ]; then
        if [ -n "$final_grep_pattern_gfwlist" ]; then final_grep_pattern_gfwlist="${final_grep_pattern_gfwlist}|(${gfwlist_key_pats})"; else final_grep_pattern_gfwlist="(${gfwlist_key_pats})"; fi
    fi
    if [ -n "$final_grep_pattern_gfwlist" ]; then printf "%s\n" "$awk_output_gfwlist_raw" | grep -Ev "$final_grep_pattern_gfwlist" > "./Temp/gfwlist_raw_new.tmp"; else printf "%s\n" "$awk_output_gfwlist_raw" > "./Temp/gfwlist_raw_new.tmp"; fi
    
    awk_output_lite_gfwlist_raw=$(awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/cnacc_trust.tmp" "./Temp/lite_gfwlist_raw.tmp")
    lite_gfwlist_excl_pats=$(cat "./Temp/lite_gfwlist_exclusion.tmp")
    lite_gfwlist_key_pats=$(cat "./Temp/lite_gfwlist_keyword.tmp")
    final_grep_pattern_lite_gfwlist=""
    if [ -n "$lite_gfwlist_excl_pats" ]; then final_grep_pattern_lite_gfwlist="(\\.(${lite_gfwlist_excl_pats})$)|(^(${lite_gfwlist_excl_pats})$)"; fi
    if [ -n "$lite_gfwlist_key_pats" ]; then
        if [ -n "$final_grep_pattern_lite_gfwlist" ]; then final_grep_pattern_lite_gfwlist="${final_grep_pattern_lite_gfwlist}|(${lite_gfwlist_key_pats})"; else final_grep_pattern_lite_gfwlist="(${lite_gfwlist_key_pats})"; fi
    fi
    if [ -n "$final_grep_pattern_lite_gfwlist" ]; then printf "%s\n" "$awk_output_lite_gfwlist_raw" | grep -Ev "$final_grep_pattern_lite_gfwlist" > "./Temp/lite_gfwlist_raw_new.tmp"; else printf "%s\n" "$awk_output_lite_gfwlist_raw" > "./Temp/lite_gfwlist_raw_new.tmp"; fi
    
    cat "./Temp/cnacc_raw.tmp" "./Temp/lite_cnacc_raw.tmp" "./Temp/cnacc_addition.tmp" "./Temp/lite_cnacc_addition.tmp" "./Temp/cnacc_trust.tmp" "./Temp/lite_cnacc_trust.tmp" | sort | uniq > "./Temp/cnacc_added.tmp"
    cat "./Temp/gfwlist_raw_new.tmp" "./Temp/lite_gfwlist_raw_new.tmp" "./Temp/gfwlist_addition.tmp" "./Temp/lite_gfwlist_addition.tmp" | sort | uniq > "./Temp/gfwlist_added.tmp"
    
    cat "./Temp/lite_cnacc_raw.tmp" "./Temp/lite_cnacc_addition.tmp" "./Temp/lite_cnacc_trust.tmp" | sort | uniq > "./Temp/lite_cnacc_added.tmp"
    cat "./Temp/lite_gfwlist_raw_new.tmp" "./Temp/lite_gfwlist_addition.tmp" | sort | uniq > "./Temp/lite_gfwlist_added.tmp"
    
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/cnacc_subtraction.tmp" "./Temp/cnacc_added.tmp" > "./Temp/cnacc_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/gfwlist_subtraction.tmp" "./Temp/gfwlist_added.tmp" > "./Temp/gfwlist_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/cnacc_subtraction.tmp" "./Temp/lite_cnacc_added.tmp" > "./Temp/lite_cnacc_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./Temp/gfwlist_subtraction.tmp" "./Temp/lite_gfwlist_added.tmp" > "./Temp/lite_gfwlist_data.tmp"

    mapfile -t cnacc_data_temp < <(cat "./Temp/cnacc_data.tmp" "./Temp/lite_cnacc_data.tmp" | sort -u)
    cnacc_data=("${cnacc_data_temp[@]}")
    
    mapfile -t gfwlist_data_temp < <(cat "./Temp/gfwlist_data.tmp" "./Temp/lite_gfwlist_data.tmp" | sort -u)
    gfwlist_data=("${gfwlist_data_temp[@]}")
    
    mapfile -t lite_cnacc_data_temp < <(cat "./Temp/lite_cnacc_data.tmp" | sort -u)
    lite_cnacc_data=("${lite_cnacc_data_temp[@]}")
    
    mapfile -t lite_gfwlist_data_temp < <(cat "./Temp/lite_gfwlist_data.tmp" | sort -u)
    lite_gfwlist_data=("${lite_gfwlist_data_temp[@]}")
    
    echo "数据分析完成。"
}

# Generate Rules
function GenerateRules() {
    # Sub-function to determine output filename and path
    function FileName() {
        if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "whiteblack" ]; then
            generate_temp="black" 
        elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "blackwhite" ]; then
            generate_temp="white" 
        else
            generate_temp="debug"
        fi

        if [ "${software_name}" == "adguardhome" ] || [ "${software_name}" == "adguardhome_new" ] || [ "${software_name}" == "domain" ]; then
            file_extension="txt"
        elif [ "${software_name}" == "bind9" ] || [ "${software_name}" == "dnsmasq" ] || [ "${software_name}" == "smartdns" ] || [ "${software_name}" == "unbound" ]; then
            file_extension="conf"
        else
            file_extension="dev" 
        fi

        # Output directories are relative to script execution root
        if [ ! -d "./gfwlist2${software_name}" ]; then
            mkdir -p "./gfwlist2${software_name}"
        fi

        file_name="${generate_temp}list_${generate_mode}.${file_extension}"
        file_path="./gfwlist2${software_name}/${file_name}"
        > "${file_path}" # Ensure the file is empty before writing
    }

    function GenerateDefaultUpstream() {
        case ${software_name} in
            adguardhome|adguardhome_new)
                # This function writes the list of default upstream DNS servers at the TOP of the rule file.
                # These are used if a domain does NOT match any specific rule further down in the file.
                if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                    # For GFW-centric lists (black or blackwhite), the default for non-matching (presumably domestic) domains should be DOMESTIC DNS.
                    for domestic_dns_task in "${!domestic_dns[@]}"; do
                        echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                    # For CNACC-centric lists (white or whiteblack), the default for non-matching (presumably foreign) domains should be FOREIGN DNS.
                    for foreign_dns_task in "${!foreign_dns[@]}"; do
                        echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                    done
                fi
            ;;
            *)
                return 0 # No default upstream for other software types in this function
            ;;
        esac
    }

    case ${software_name} in
        adguardhome)
            domestic_dns=( "https://doh.pub:443/dns-query" )
            foreign_dns=( "https://dns.opendns.com:443/dns-query" )
            function GenerateRulesHeader() { echo -n "[/" >> "${file_path}"; }
            function GenerateRulesBody() {
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then 
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"; done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then 
                        for cnacc_data_task in "${!cnacc_data[@]}"; do echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"; done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"; done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"; done
                    fi
                fi
            }
            function GenerateRulesFooter() {
                sed -i 's/\/$//' "${file_path}" # Remove trailing slash if any domains were added
                if [ "${dns_mode}" == "default" ]; then echo -e "]#" >> "${file_path}";
                elif [ "${dns_mode}" == "domestic" ]; then echo -e "]${domestic_dns[0]}" >> "${file_path}"; 
                elif [ "${dns_mode}" == "foreign" ]; then echo -e "]${foreign_dns[0]}" >> "${file_path}"; fi
            }
            function GenerateRulesProcess() {
                domain_count=0
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#gfwlist_data[@]} -gt 0 ]; then domain_count=${#gfwlist_data[@]};
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#cnacc_data[@]} -gt 0 ]; then domain_count=${#cnacc_data[@]}; fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                     if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#lite_gfwlist_data[@]} -gt 0 ]; then domain_count=${#lite_gfwlist_data[@]};
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#lite_cnacc_data[@]} -gt 0 ]; then domain_count=${#lite_cnacc_data[@]}; fi
                fi
                if [ ${domain_count} -gt 0 ]; then GenerateRulesHeader; GenerateRulesBody; GenerateRulesFooter;
                else if ! grep -qE 'tls://|https://' "${file_path}"; then > "${file_path}"; fi; fi # Avoid creating empty rule files unless they contain default upstreams
            }
            FileName 
            if [[ "${generate_mode}" == "full_combine" || "${generate_mode}" == "lite_combine" ]]; then GenerateDefaultUpstream; GenerateRulesProcess;
            elif [[ "${dns_mode}" == "default" ]]; then GenerateDefaultUpstream; GenerateRulesProcess; 
            elif [[ "${dns_mode}" == "domestic" || "${dns_mode}" == "foreign" ]]; then GenerateDefaultUpstream; GenerateRulesProcess; fi
        ;;
        adguardhome_new) 
            domestic_dns=( "https://doh.pub:443/dns-query" "tls://dns.alidns.com:853" )
            foreign_dns=( "https://dns.opendns.com:443/dns-query" "tls://dns.google:853" )
            function GenerateRulesHeader() { echo -n "[/" >> "${file_path}"; }
            function GenerateRulesBody() { 
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"; done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for cnacc_data_task in "${!cnacc_data[@]}"; do echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"; done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"; done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"; done
                    fi
                fi
            }
            function GenerateRulesFooter() {
                sed -i 's/\/$//' "${file_path}" 
                if [ "${dns_mode}" == "default" ]; then echo -e "]#" >> "${file_path}";
                elif [ "${dns_mode}" == "domestic" ]; then echo -e "]${domestic_dns[*]}" >> "${file_path}";
                elif [ "${dns_mode}" == "foreign" ]; then echo -e "]${foreign_dns[*]}" >> "${file_path}"; fi
            }
            function GenerateRulesProcess() { 
                domain_count=0
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#gfwlist_data[@]} -gt 0 ]; then domain_count=${#gfwlist_data[@]};
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#cnacc_data[@]} -gt 0 ]; then domain_count=${#cnacc_data[@]}; fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                     if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#lite_gfwlist_data[@]} -gt 0 ]; then domain_count=${#lite_gfwlist_data[@]};
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#lite_cnacc_data[@]} -gt 0 ]; then domain_count=${#lite_cnacc_data[@]}; fi
                fi
                if [ ${domain_count} -gt 0 ]; then GenerateRulesHeader; GenerateRulesBody; GenerateRulesFooter;
                else if ! grep -qE 'tls://|https://' "${file_path}"; then > "${file_path}"; fi; fi
            }
            FileName; GenerateDefaultUpstream; GenerateRulesProcess
        ;;
        bind9)
            domestic_dns=( "223.5.5.5 port 53" )
            foreign_dns=( "8.8.8.8 port 53" )
            FileName 
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then 
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo -n "zone \"${gfwlist_data[$gfwlist_data_task]}.\" {type forward; forwarders { "; for foreign_dns_item in "${foreign_dns[@]}"; do echo -n "${foreign_dns_item}; " >> "${file_path}"; done; echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then 
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo -n "zone \"${cnacc_data[$cnacc_data_task]}.\" {type forward; forwarders { "; for domestic_dns_item in "${domestic_dns[@]}"; do echo -n "${domestic_dns_item}; " >> "${file_path}"; done; echo "}; };" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo -n "zone \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\" {type forward; forwarders { "; for foreign_dns_item in "${foreign_dns[@]}"; do echo -n "${foreign_dns_item}; " >> "${file_path}"; done; echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo -n "zone \"${lite_cnacc_data[$lite_cnacc_data_task]}.\" {type forward; forwarders { "; for domestic_dns_item in "${domestic_dns[@]}"; do echo -n "${domestic_dns_item}; " >> "${file_path}"; done; echo "}; };" >> "${file_path}"
                    done
                fi
            fi
        ;;
        dnsmasq)
            domestic_dns=( "223.5.5.5#53" )
            foreign_dns=( "8.8.8.8#53" )
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do for foreign_dns_item in "${foreign_dns[@]}"; do echo "server=/${gfwlist_data[$gfwlist_data_task]}/${foreign_dns_item}" >> "${file_path}"; done; done
                elif [ "${generate_file}" == "white" ]; then
                    for cnacc_data_task in "${!cnacc_data[@]}"; do for domestic_dns_item in "${domestic_dns[@]}"; do echo "server=/${cnacc_data[$cnacc_data_task]}/${domestic_dns_item}" >> "${file_path}"; done; done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do for foreign_dns_item in "${foreign_dns[@]}"; do echo "server=/${lite_gfwlist_data[$lite_gfwlist_data_task]}/${foreign_dns_item}" >> "${file_path}"; done; done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do for domestic_dns_item in "${domestic_dns[@]}"; do echo "server=/${lite_cnacc_data[$lite_cnacc_data_task]}/${domestic_dns_item}" >> "${file_path}"; done; done
                fi
            fi
        ;;
        domain) 
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then for gfwlist_data_task in "${!gfwlist_data[@]}"; do echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"; done
                elif [ "${generate_file}" == "white" ]; then for cnacc_data_task in "${!cnacc_data[@]}"; do echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"; done; fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do echo "${lite_gfwlist_data[$lite_gfwlist_data_task]}" >> "${file_path}"; done
                elif [ "${generate_file}" == "white" ]; then for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do echo "${lite_cnacc_data[$lite_cnacc_data_task]}" >> "${file_path}"; done; fi
            fi
        ;;
        smartdns)
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then for gfwlist_data_task in "${!gfwlist_data[@]}"; do echo "nameserver /${gfwlist_data[$gfwlist_data_task]}/${foreign_group:-foreign}" >> "${file_path}"; done
                elif [ "${generate_file}" == "white" ]; then for cnacc_data_task in "${!cnacc_data[@]}"; do echo "nameserver /${cnacc_data[$cnacc_data_task]}/${domestic_group:-domestic}" >> "${file_path}"; done; fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do echo "nameserver /${lite_gfwlist_data[$lite_gfwlist_data_task]}/${foreign_group:-foreign}" >> "${file_path}"; done
                elif [ "${generate_file}" == "white" ]; then for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do echo "nameserver /${lite_cnacc_data[$lite_cnacc_data_task]}/${domestic_group:-domestic}" >> "${file_path}"; done; fi
            fi
        ;;
        unbound)
            domestic_dns=( "223.5.5.5@853#dns.alidns.com" )
            foreign_dns=( "8.8.8.8@853#dns.google" )
            forward_ssl_tls_upstream="yes" 
            function GenerateRulesHeader() { echo "forward-zone:" >> "${file_path}"; }
            function GenerateRulesFooter() { 
                if [ "${dns_mode}" == "domestic" ]; then for domestic_dns_item in "${domestic_dns[@]}"; do echo "    forward-addr: ${domestic_dns_item}" >> "${file_path}"; done
                elif [ "${dns_mode}" == "foreign" ]; then for foreign_dns_item in "${foreign_dns[@]}"; do echo "    forward-addr: ${foreign_dns_item}" >> "${file_path}"; done; fi
                echo "    forward-tls-upstream: ${forward_ssl_tls_upstream}" >> "${file_path}"; 
            }
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then for gfwlist_data_task in "${!gfwlist_data[@]}"; do GenerateRulesHeader && echo "    name: \"${gfwlist_data[$gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter; done
                elif [ "${generate_file}" == "white" ]; then for cnacc_data_task in "${!cnacc_data[@]}"; do GenerateRulesHeader && echo "    name: \"${cnacc_data[$cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter; done; fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do GenerateRulesHeader && echo "    name: \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter; done
                elif [ "${generate_file}" == "white" ]; then for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do GenerateRulesHeader && echo "    name: \"${lite_cnacc_data[$lite_cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter; done; fi
            fi
        ;;
        *)
            echo "错误：未知的 software_name: ${software_name}"
            return 1
    esac
}

# Output Data
function OutputData() {
    echo "开始生成规则文件..."
    ## AdGuard Home
    # Files for GFW domains (black), using FOREIGN_DNS for rules, with DOMESTIC_DNS as default at top
    software_name="adguardhome" && generate_file="black" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome" && generate_file="black" && generate_mode="lite_combine" && dns_mode="foreign" && GenerateRules 
    # Files for CNACC domains (white), using DOMESTIC_DNS for rules, with FOREIGN_DNS as default at top
    software_name="adguardhome" && generate_file="white" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="lite_combine" && dns_mode="domestic" && GenerateRules 
    
    # These generate files with specific rule upstreams, and appropriate default upstreams at the top
    software_name="adguardhome" && generate_file="black" && generate_mode="full" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome" && generate_file="black" && generate_mode="lite" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="full" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="lite" && dns_mode="domestic" && GenerateRules 

    ## AdGuard Home (New) - Same logic as above
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="black" && generate_mode="lite_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="lite_combine" && dns_mode="domestic" && GenerateRules
    
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome_new" && generate_file="black" && generate_mode="lite" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome_new" && generate_file="white" && generate_mode="lite" && dns_mode="domestic" && GenerateRules 

    ## Bind9
    software_name="bind9" && generate_file="black" && generate_mode="full" && dns_mode="foreign" && GenerateRules 
    software_name="bind9" && generate_file="black" && generate_mode="lite" && dns_mode="foreign" && GenerateRules
    software_name="bind9" && generate_file="white" && generate_mode="full" && dns_mode="domestic" && GenerateRules
    software_name="bind9" && generate_file="white" && generate_mode="lite" && dns_mode="domestic" && GenerateRules

    ## DNSMasq
    software_name="dnsmasq" && generate_file="black" && generate_mode="full" && dns_mode="foreign" && GenerateRules
    software_name="dnsmasq" && generate_file="black" && generate_mode="lite" && dns_mode="foreign" && GenerateRules
    software_name="dnsmasq" && generate_file="white" && generate_mode="full" && dns_mode="domestic" && GenerateRules
    software_name="dnsmasq" && generate_file="white" && generate_mode="lite" && dns_mode="domestic" && GenerateRules

    ## Domain (Plain list)
    software_name="domain" && generate_file="black" && generate_mode="full" && GenerateRules 
    software_name="domain" && generate_file="black" && generate_mode="lite" && GenerateRules 
    software_name="domain" && generate_file="white" && generate_mode="full" && GenerateRules 
    software_name="domain" && generate_file="white" && generate_mode="lite" && GenerateRules 

    ## SmartDNS
    software_name="smartdns" && generate_file="black" && generate_mode="full" && foreign_group="foreign" && GenerateRules
    software_name="smartdns" && generate_file="black" && generate_mode="lite" && foreign_group="foreign" && GenerateRules
    software_name="smartdns" && generate_file="white" && generate_mode="full" && domestic_group="domestic" && GenerateRules
    software_name="smartdns" && generate_file="white" && generate_mode="lite" && domestic_group="domestic" && GenerateRules

    ## Unbound
    software_name="unbound" && generate_file="black" && generate_mode="full" && dns_mode="foreign" && GenerateRules
    software_name="unbound" && generate_file="black" && generate_mode="lite" && dns_mode="foreign" && GenerateRules
    software_name="unbound" && generate_file="white" && generate_mode="full" && dns_mode="domestic" && GenerateRules
    software_name="unbound" && generate_file="white" && generate_mode="lite" && dns_mode="domestic" && GenerateRules

    echo "GFWList2AGH 脚本已完成规则生成。"
}

## Process
# Call GetData
GetData
# Call AnalyseData
AnalyseData

# --- 新增的数据统计 ---
echo "--- 数据统计 ---"
echo "CN域名 (cnacc_data) 条数: ${#cnacc_data[@]}"
echo "GFW域名 (gfwlist_data) 条数: ${#gfwlist_data[@]}"
echo "精简CN域名 (lite_cnacc_data) 条数: ${#lite_cnacc_data[@]}"
echo "精简GFW域名 (lite_gfwlist_data) 条数: ${#lite_gfwlist_data[@]}"
echo "--------------"
# --- 数据统计结束 ---

# Call OutputData
OutputData

# Clean up Temp directory at the end of the script
rm -rf ./Temp
echo "临时目录 ./Temp 已清理。"
exit 0
