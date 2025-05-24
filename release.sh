#!/bin/bash

# Current Version: 1.2.9 (已修改数据源)

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && bash ./GFWList2AGH/release.sh

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
    # GFW lists (Base64 encoded) - 此部分已移除，因为新的GFW源是纯文本
    # gfwlist_base64=( ... )

    # Array of URLs for GFW lists (plain text domains) - 已更新数据源
    gfwlist_domain=(
        "https://raw.githubusercontent.com/jqyisbest/CustomDiversionRules/refs/heads/main/rules/gfw/gfw_domain_list.txt"
    )
    # Array of URLs for custom modification data for this script
    gfwlist2agh_modify=(
        "https://raw.githubusercontent.com/jqyisbest/GFWList2AGH/source/data/data_modify.txt"
    )

    # Remove any existing temporary files/directories and create a new Temp directory
    rm -rf ./gfwlist2* ./Temp && mkdir ./Temp && cd ./Temp

    # Download and process cnacc_domain lists
    echo "正在下载 CN 域名列表..."
    for cnacc_domain_task in "${!cnacc_domain[@]}"; do
        curl -s --connect-timeout 15 "${cnacc_domain[$cnacc_domain_task]}" | sed "s/^\.//g" >> ./cnacc_domain.tmp
    done
    echo "CN 域名列表下载完成。"

    # Download cnacc_trusted lists
    echo "正在下载受信任 CN 域名列表..."
    for cnacc_trusted_task in "${!cnacc_trusted[@]}"; do
        curl -s --connect-timeout 15 "${cnacc_trusted[$cnacc_trusted_task]}" >> ./cnacc_trusted.tmp
    done
    echo "受信任 CN 域名列表下载完成。"

    # Download and decode gfwlist_base64 lists - 此部分已移除
    # for gfwlist_base64_task in "${!gfwlist_base64[@]}"; do
    #     curl -s --connect-timeout 15 "${gfwlist_base64[$gfwlist_base64_task]}" | base64 -d >> ./gfwlist_base64.tmp
    # done

    # Download and process gfwlist_domain lists
    echo "正在下载 GFW 域名列表..."
    for gfwlist_domain_task in "${!gfwlist_domain[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_domain[$gfwlist_domain_task]}" | sed "s/^\.//g" >> ./gfwlist_domain.tmp
    done
    echo "GFW 域名列表下载完成。"

    # Download gfwlist2agh_modify list
    echo "正在下载自定义修改列表..."
    for gfwlist2agh_modify_task in "${!gfwlist2agh_modify[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist2agh_modify[$gfwlist2agh_modify_task]}" >> ./gfwlist2agh_modify.tmp
    done
    echo "自定义修改列表下载完成。"
}

# Analyse Data
function AnalyseData() {
    echo "开始分析数据..."
    # Define domain regex patterns
    domain_regex="^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"
    lite_domain_regex="^([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"

    # Process gfwlist2agh_modify.tmp to extract various modification rules
    # cnacc_addition: Domains to add to Chinese accelerated list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\@\%\@\)\|\(\@\%\!\)\|\(\!\&\@\)\|\(\@\@\@\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./cnacc_addition.tmp"
    # cnacc_subtraction: Domains to remove from Chinese accelerated list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\!\)\|\(\@\&\!\)\|\(\!\%\@\)\|\(\!\!\!\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./cnacc_subtraction.tmp"
    # cnacc_exclusion: Domains patterns to exclude from Chinese accelerated list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\%\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./cnacc_exclusion.tmp"
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\%\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./lite_cnacc_exclusion.tmp"
    # cnacc_keyword: Keywords to filter from Chinese accelerated list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./cnacc_keyword.tmp"
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\%\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./lite_cnacc_keyword.tmp"

    # gfwlist_addition: Domains to add to GFW list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\@\&\@\)\|\(\@\&\!\)\|\(\!\%\@\)\|\(\@\@\@\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./gfwlist_addition.tmp"
    # gfwlist_subtraction: Domains to remove from GFW list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\!\)\|\(\@\%\!\)\|\(\!\&\@\)\|\(\!\!\!\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | sort | uniq > "./gfwlist_subtraction.tmp"
    # gfwlist_exclusion: Domain patterns to exclude from GFW list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\&\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./gfwlist_exclusion.tmp"
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\*\&\*\)\|\(\*\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./lite_gfwlist_exclusion.tmp"
    # gfwlist_keyword: Keywords to filter from GFW list
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./gfwlist_keyword.tmp"
    cat "./gfwlist2agh_modify.tmp" | grep -v "\#" | grep "\(\!\&\*\)\|\(\!\*\*\)" | tr -d "\!\%\&\(\)\*\@" | grep -E "${lite_domain_regex}" | xargs | sed "s/\ /\|/g" | sort | uniq > "./lite_gfwlist_keyword.tmp"

    # Create lite versions of addition lists
    cat "./cnacc_addition.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./lite_cnacc_addition.tmp"
    cat "./gfwlist_addition.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./lite_gfwlist_addition.tmp"

    # Process cnacc_trusted lists
    cat "./cnacc_trusted.tmp" | sed "s/\/114\.114\.114\.114//g;s/server\=\///g" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./cnacc_trust.tmp"
    cat "./cnacc_trust.tmp" | grep -E "${lite_domain_regex}" | sort | uniq > "./lite_cnacc_trust.tmp"

    # Process cnacc_domain lists
    cat "./cnacc_domain.tmp" | sed "s/domain\://g;s/full\://g" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./cnacc_checklist.tmp"
    # Process gfwlist (domain) lists - 移除了 gfwlist_.tmp
    cat "./gfwlist_domain.tmp" | sed "s/domain\://g;s/full\://g;s/http\:\/\///g;s/https\:\/\///g" | tr -d "|" | tr "A-Z" "a-z" | grep -E "${domain_regex}" | sort | uniq > "./gfwlist_checklist.tmp"

    # Create lite versions of checklist files (extracting second-level domains)
    cat "./cnacc_checklist.tmp" | rev | cut -d "." -f 1,2 | rev | sort | uniq > "./lite_cnacc_checklist.tmp"
    cat "./gfwlist_checklist.tmp" | rev | cut -d "." -f 1,2 | rev | sort | uniq > "./lite_gfwlist_checklist.tmp"

    # Generate raw GFW list (domains in gfwlist_checklist but not in cnacc_checklist)
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./cnacc_checklist.tmp" "./gfwlist_checklist.tmp" > "./gfwlist_raw.tmp"
    # Generate raw CNACC list (domains in cnacc_checklist but not in gfwlist_checklist), apply exclusions and keyword filters
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./gfwlist_checklist.tmp" "./cnacc_checklist.tmp" | grep -Ev "(\.($(cat './cnacc_exclusion.tmp'))$)|(^$(cat './cnacc_exclusion.tmp')$)|($(cat './cnacc_keyword.tmp'))" > "./cnacc_raw.tmp"

    # Generate lite versions of raw lists
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./lite_cnacc_checklist.tmp" "./lite_gfwlist_checklist.tmp" > "./lite_gfwlist_raw.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./lite_gfwlist_checklist.tmp" "./lite_cnacc_checklist.tmp" | grep -Ev "(\.($(cat './lite_cnacc_exclusion.tmp'))$)|(^$(cat './lite_cnacc_exclusion.tmp')$)|($(cat './lite_cnacc_keyword.tmp'))" > "./lite_cnacc_raw.tmp"

    # Refine GFW list by removing trusted CNACC domains and applying GFW exclusions/keywords
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./cnacc_trust.tmp" "./gfwlist_raw.tmp" | grep -Ev "(\.($(cat './gfwlist_exclusion.tmp'))$)|(^$(cat './gfwlist_exclusion.tmp')$)|($(cat './gfwlist_keyword.tmp'))" > "./gfwlist_raw_new.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./cnacc_trust.tmp" "./lite_gfwlist_raw.tmp" | grep -Ev "(\.($(cat './lite_gfwlist_exclusion.tmp'))$)|(^$(cat './lite_gfwlist_exclusion.tmp')$)|($(cat './lite_gfwlist_keyword.tmp'))" > "./lite_gfwlist_raw_new.tmp"

    # Combine raw lists, additions, and trusted lists for final CNACC and GFW lists
    cat "./cnacc_raw.tmp" "./lite_cnacc_raw.tmp" "./cnacc_addition.tmp" "./lite_cnacc_addition.tmp" "./cnacc_trust.tmp" "./lite_cnacc_trust.tmp" | sort | uniq > "./cnacc_added.tmp"
    cat "./gfwlist_raw_new.tmp" "./lite_gfwlist_raw_new.tmp" "./gfwlist_addition.tmp" "./lite_gfwlist_addition.tmp" | sort | uniq > "./gfwlist_added.tmp"

    # Create lite versions of combined lists
    cat "./lite_cnacc_raw.tmp" "./lite_cnacc_addition.tmp" "./lite_cnacc_trust.tmp" | sort | uniq > "./lite_cnacc_added.tmp"
    cat "./lite_gfwlist_raw_new.tmp" "./lite_gfwlist_addition.tmp" | sort | uniq > "./lite_gfwlist_added.tmp"

    # Apply subtractions to get final data lists
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./cnacc_subtraction.tmp" "./cnacc_added.tmp" > "./cnacc_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./gfwlist_subtraction.tmp" "./gfwlist_added.tmp" > "./gfwlist_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./cnacc_subtraction.tmp" "./lite_cnacc_added.tmp" > "./lite_cnacc_data.tmp"
    awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' "./gfwlist_subtraction.tmp" "./lite_gfwlist_added.tmp" > "./lite_gfwlist_data.tmp"

    # Populate shell arrays with the final domain lists
    cnacc_data=($(cat "./cnacc_data.tmp" "./lite_cnacc_data.tmp" | sort | uniq | awk "{ print $0 }"))
    gfwlist_data=($(cat "./gfwlist_data.tmp" "./lite_gfwlist_data.tmp" | sort | uniq | awk "{ print $0 }"))
    lite_cnacc_data=($(cat "./lite_cnacc_data.tmp" | sort | uniq | awk "{ print $0 }"))
    lite_gfwlist_data=($(cat "./lite_gfwlist_data.tmp" | sort | uniq | awk "{ print $0 }"))
    echo "数据分析完成。"
}

# Generate Rules
function GenerateRules() {
    # Sub-function to determine output filename and path
    function FileName() {
        if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "whiteblack" ]; then
            generate_temp="black" # Typically for GFW list, routed via foreign DNS
        elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "blackwhite" ]; then
            generate_temp="white" # Typically for CNACC list, routed via domestic DNS
        else
            generate_temp="debug"
        fi

        if [ "${software_name}" == "adguardhome" ] || [ "${software_name}" == "adguardhome_new" ] || [ "${software_name}" == "domain" ]; then
            file_extension="txt"
        elif [ "${software_name}" == "bind9" ] || [ "${software_name}" == "dnsmasq" ] || [ "${software_name}" == "smartdns" ] || [ "${software_name}" == "unbound" ]; then
            file_extension="conf"
        else
            file_extension="dev" # Default/development extension
        fi

        # Create directory for the specific software if it doesn't exist
        if [ ! -d "../gfwlist2${software_name}" ]; then
            mkdir "../gfwlist2${software_name}"
        fi

        file_name="${generate_temp}list_${generate_mode}.${file_extension}"
        file_path="../gfwlist2${software_name}/${file_name}"
        # Ensure the file is empty before writing
        > "${file_path}"
    }

    # Sub-function to generate default upstream DNS for AdGuard Home
    function GenerateDefaultUpstream() {
        case ${software_name} in
            adguardhome|adguardhome_new)
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "full_combine" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "blackwhite" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "whiteblack" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    fi
                else 
                    if [ "${generate_file}" == "black" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    fi
                fi
            ;;
            *)
                return 0
            ;;
        esac
    }

    case ${software_name} in
        adguardhome)
            domestic_dns=(
                "https://doh.pub:443/dns-query"
            )
            foreign_dns=(
                "https://dns.opendns.com:443/dns-query"
            )
            function GenerateRulesHeader() {
                echo -n "[/" >> "${file_path}"
            }
            function GenerateRulesBody() {
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then 
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do 
                            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then 
                        for cnacc_data_task in "${!cnacc_data[@]}"; do 
                            echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"
                        done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do 
                            echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do 
                            echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"
                        done
                    fi
                fi
            }
            function GenerateRulesFooter() {
                sed -i 's/\/$//' "${file_path}" 

                if [ "${dns_mode}" == "default" ]; then 
                    echo -e "]#" >> "${file_path}"
                elif [ "${dns_mode}" == "domestic" ]; then
                    echo -e "]${domestic_dns[0]}" >> "${file_path}" 
                elif [ "${dns_mode}" == "foreign" ]; then
                     echo -e "]${foreign_dns[0]}" >> "${file_path}" 
                fi
            }
            function GenerateRulesProcess() {
                domain_count=0
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#gfwlist_data[@]} -gt 0 ]; then
                        domain_count=${#gfwlist_data[@]}
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#cnacc_data[@]} -gt 0 ]; then
                        domain_count=${#cnacc_data[@]}
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                     if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#lite_gfwlist_data[@]} -gt 0 ]; then
                        domain_count=${#lite_gfwlist_data[@]}
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#lite_cnacc_data[@]} -gt 0 ]; then
                        domain_count=${#lite_cnacc_data[@]}
                    fi
                fi

                if [ ${domain_count} -gt 0 ]; then
                    GenerateRulesHeader
                    GenerateRulesBody
                    GenerateRulesFooter
                else
                    if ! grep -qE 'tls://|https://' "${file_path}"; then 
                        > "${file_path}" 
                    fi
                fi
            }

            FileName 
            if [[ "${generate_mode}" == "full_combine" || "${generate_mode}" == "lite_combine" ]]; then
                GenerateDefaultUpstream 
                GenerateRulesProcess
            elif [[ "${dns_mode}" == "default" ]]; then 
                 GenerateDefaultUpstream 
                 GenerateRulesProcess
            elif [[ "${dns_mode}" == "domestic" || "${dns_mode}" == "foreign" ]]; then
                 GenerateDefaultUpstream 
                 GenerateRulesProcess
            fi
        ;;
        adguardhome_new) 
            domestic_dns=(
                "https://doh.pub:443/dns-query"
                "tls://dns.alidns.com:853" 
            )
            foreign_dns=(
                "https://dns.opendns.com:443/dns-query"
                "tls://dns.google:853" 
            )
            function GenerateRulesHeader() {
                echo -n "[/" >> "${file_path}"
            }
            function GenerateRulesBody() { 
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for cnacc_data_task in "${!cnacc_data[@]}"; do
                            echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"
                        done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                            echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                            echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"
                        done
                    fi
                fi
            }
            function GenerateRulesFooter() {
                sed -i 's/\/$//' "${file_path}" 

                if [ "${dns_mode}" == "default" ]; then
                    echo -e "]#" >> "${file_path}"
                elif [ "${dns_mode}" == "domestic" ]; then
                    echo -e "]${domestic_dns[*]}" >> "${file_path}"
                elif [ "${dns_mode}" == "foreign" ]; then
                    echo -e "]${foreign_dns[*]}" >> "${file_path}"
                fi
            }
             function GenerateRulesProcess() { 
                domain_count=0
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#gfwlist_data[@]} -gt 0 ]; then
                        domain_count=${#gfwlist_data[@]}
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#cnacc_data[@]} -gt 0 ]; then
                        domain_count=${#cnacc_data[@]}
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                     if { [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; } && [ ${#lite_gfwlist_data[@]} -gt 0 ]; then
                        domain_count=${#lite_gfwlist_data[@]}
                    elif { [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; } && [ ${#lite_cnacc_data[@]} -gt 0 ]; then
                        domain_count=${#lite_cnacc_data[@]}
                    fi
                fi

                if [ ${domain_count} -gt 0 ]; then
                    GenerateRulesHeader
                    GenerateRulesBody
                    GenerateRulesFooter
                else
                    if ! grep -qE 'tls://|https://' "${file_path}"; then 
                        > "${file_path}" 
                    fi
                fi
            }

            FileName
            GenerateDefaultUpstream 
            GenerateRulesProcess
        ;;
        bind9)
            domestic_dns=(
                "223.5.5.5 port 53" 
            )
            foreign_dns=(
                "8.8.8.8 port 53"   
            )
            FileName 
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then 
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo -n "zone \"${gfwlist_data[$gfwlist_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for foreign_dns_item in "${foreign_dns[@]}"; do 
                            echo -n "${foreign_dns_item}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then 
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo -n "zone \"${cnacc_data[$cnacc_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for domestic_dns_item in "${domestic_dns[@]}"; do 
                            echo -n "${domestic_dns_item}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo -n "zone \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for foreign_dns_item in "${foreign_dns[@]}"; do
                            echo -n "${foreign_dns_item}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo -n "zone \"${lite_cnacc_data[$lite_cnacc_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for domestic_dns_item in "${domestic_dns[@]}"; do
                            echo -n "${domestic_dns_item}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                fi
            fi
        ;;
        dnsmasq)
            domestic_dns=(
                "223.5.5.5#53"
            )
            foreign_dns=(
                "8.8.8.8#53"
            )
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        for foreign_dns_item in "${foreign_dns[@]}"; do
                            echo "server=/${gfwlist_data[$gfwlist_data_task]}/${foreign_dns_item}" >> "${file_path}"
                        done
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        for domestic_dns_item in "${domestic_dns[@]}"; do
                            echo "server=/${cnacc_data[$cnacc_data_task]}/${domestic_dns_item}" >> "${file_path}"
                        done
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        for foreign_dns_item in "${foreign_dns[@]}"; do
                            echo "server=/${lite_gfwlist_data[$lite_gfwlist_data_task]}/${foreign_dns_item}" >> "${file_path}"
                        done
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        for domestic_dns_item in "${domestic_dns[@]}"; do
                            echo "server=/${lite_cnacc_data[$lite_cnacc_data_task]}/${domestic_dns_item}" >> "${file_path}"
                        done
                    done
                fi
            fi
        ;;
        domain) 
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then 
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then 
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo "${lite_gfwlist_data[$lite_gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo "${lite_cnacc_data[$lite_cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            fi
        ;;
        smartdns)
            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then 
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo "nameserver /${gfwlist_data[$gfwlist_data_task]}/${foreign_group:-foreign}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then 
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo "nameserver /${cnacc_data[$cnacc_data_task]}/${domestic_group:-domestic}" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo "nameserver /${lite_gfwlist_data[$lite_gfwlist_data_task]}/${foreign_group:-foreign}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo "nameserver /${lite_cnacc_data[$lite_cnacc_data_task]}/${domestic_group:-domestic}" >> "${file_path}"
                    done
                fi
            fi
        ;;
        unbound)
            domestic_dns=( 
                "223.5.5.5@853#dns.alidns.com"
            )
            foreign_dns=( 
                "8.8.8.8@853#dns.google"
            )
            forward_ssl_tls_upstream="yes" 

            function GenerateRulesHeader() { 
                echo "forward-zone:" >> "${file_path}"
            }
            function GenerateRulesFooter() { 
                if [ "${dns_mode}" == "domestic" ]; then
                    for domestic_dns_item in "${domestic_dns[@]}"; do
                        echo "    forward-addr: ${domestic_dns_item}" >> "${file_path}" 
                    done
                elif [ "${dns_mode}" == "foreign" ]; then
                    for foreign_dns_item in "${foreign_dns[@]}"; do
                        echo "    forward-addr: ${foreign_dns_item}" >> "${file_path}" 
                    done
                fi
                echo "    forward-tls-upstream: ${forward_ssl_tls_upstream}" >> "${file_path}" 
            }

            FileName
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then 
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${gfwlist_data[$gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                elif [ "${generate_file}" == "white" ]; then 
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${cnacc_data[$cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                elif [ "${generate_file}" == "white" ]; then
                    for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${lite_cnacc_data[$lite_cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                fi
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
    software_name="adguardhome" && generate_file="black" && generate_mode="full_combine" && dns_mode="default" && GenerateRules 
    software_name="adguardhome" && generate_file="black" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="full_combine" && dns_mode="default" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules 

    software_name="adguardhome" && generate_file="blackwhite" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome" && generate_file="blackwhite" && generate_mode="lite_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome" && generate_file="whiteblack" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome" && generate_file="whiteblack" && generate_mode="lite_combine" && dns_mode="foreign" && GenerateRules

    software_name="adguardhome" && generate_file="black" && generate_mode="full" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome" && generate_file="black" && generate_mode="lite" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="full" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome" && generate_file="white" && generate_mode="lite" && dns_mode="foreign" && GenerateRules 


    ## AdGuard Home (New) 
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="black" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules

    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="lite_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="lite_combine" && dns_mode="foreign" && GenerateRules
    
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome_new" && generate_file="black" && generate_mode="lite" && dns_mode="domestic" && GenerateRules 
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full" && dns_mode="foreign" && GenerateRules 
    software_name="adguardhome_new" && generate_file="white" && generate_mode="lite" && dns_mode="foreign" && GenerateRules 

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

    cd .. && rm -rf ./Temp
    echo "GFWList2AGH 脚本已完成规则生成。"
    exit 0
}

## Process
# Call GetData
GetData
# Call AnalyseData
AnalyseData
# Call OutputData
OutputData
