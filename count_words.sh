#!/bin/bash
## @file       count_words.sh
## @date       2021-11-01
## @system     linux, macOS, "Windows Subsystem for Linux"
## @parameters 1.st path 
## @details    counts words from word list in text file + highlighted html
## make file executable  with command: chmod +x count_words.sh
## add the words to count_words.list
## usage: ./count_words.sh "./path/to/folder/with/text/files"
## output: <timestamp>.csv and <timestamp>.html

sdir="$(dirname -- "$0")/" ## current script directory
scrname="$(basename -- "${0}")"
timestamp=$(date +"%Y-%m-%d_%H%M%S")
cd "${sdir}" ;
output="$(pwd)/${timestamp}.csv"
htmlout="$(pwd)/${timestamp}.html"
inputfiles=("./group/01/board01_01.txt" "./group/01/board01_03.txt"  './group/01/board01_02 (copy 1).txt')
searchlist=./${scrname%.*}.list
declare -a wordlist=("a" "and" "be" "have" "I" "in" "it" "of" "the" "this" "that" "to" )
ext=.txt
html_header='<!doctype html>'
html_root_start='<html itemscope="" itemtype="http://schema.org/WebPage">'
html_style='<style>mark{background-color: yellow; color: black;}</style>'
html_head='<head><title>counted words highlighted</title><meta charset="UTF-8">'${html_style}'</head>'
html_body_start='<body class="background"><h2>counted words highlighted</h2>'
html_body_end='</body>'
html_root_end='</html>'
html_start="${html_header}${html_root_start}${html_head}${html_body_start}"
html_end="${html_body_end}${html_root_end}"

# default values 
inputList=
if [ -f "${searchlist}" ]; then  
 wordlist=()
 echo "load search list"
 readarray rows < "${searchlist}"                                           
 for row in "${rows[@]}"; do inputList="${inputList} ${row}"; done 
 wordlist=($(echo -e "${inputList}" | sort | uniq ))
 wordlistreverse=($(echo -e "${inputList}" | sort -r | uniq ))
fi

if [ -f "${1}" ];then inputfiles=("${1}"); fi
if [ -d "${1}" ];then cd "${1}"; inputfiles=$(find . -type f -name "*${ext}"|sort) ; fi

# count words in  input file 

declare -i file_count=0
declare -A files=()
while IFS=$'\n' read -r line; do 
 file_count+=1
 files[$file_count]=${line}
done <<< "${inputfiles}"

echo " file count: ${file_count}, array size: ${#files[@]}"

for ((i = 1; i <=${#files[@]}; i++)); do
 echo "index: $i: file: ${files[$i]}"
done

# write header to csv
fields="${wordlist[@]}"
echo '"file";total;matches;ratio;'"${fields// /;}" > "${output}"
echo "${html_start}" > "${htmlout}"

for ((i = 1; i <= ${#files[@]}; i++)); do
  declare -A dictionary=()
  declare -i total=0
  declare -i matches=0
  declare  ratio=0
  result= 
 
  inputstring=$(if [ -f "${files[$i]}" ];then cat "${files[$i]}" ;fi|sed -z 's/\n\n/\n/g' |sed -z 's/\n/ /g' |sed -z 's/\t\t/\t/g' |sed -z 's/\r//g' |sed 's/\\/\//g' |sed -z 's/>/_/g' |sed -z 's/</&#60;/g' |sed -z 's/&/&#38;/g' )
  echo '<h3><a href="'${files[$i]}'">'${files[$i]}'</a></h3>'>> "${htmlout}"

 if [ -f "${files[$i]}" ]; then
 echo "searching ${files[$i]}"
  # case sensitive
  # word_count=$(egrep -o "\b[[:alpha:]]+\b" "${inputfile}" | awk ' { wcount[$0]++ } END { for(word in wcount){ printf("%s=%d\n",word ,wcount[word]); } }')
  # not case sensitive
  word_count=$(egrep -o "\b[[:alpha:]]+\b" "${files[$i]}" | awk '{print tolower($0)}' | awk ' { wcount[$0]++ } END { for(word in wcount){ printf("%s=%d\n",word ,wcount[word]); } }')
  total=$(wc "${files[$i]}" | awk  '{print $2}' )

  # echo "create dictionary"

  for word in ${word_count}; do
   key="$(echo ${word} | awk 'BEGIN {FS="="}{print $1}')"
   value="$(echo ${word} | awk 'BEGIN {FS="="}{print $2}')"
   dictionary["${key}"]=${value}
  done

  # check if search words are in dictionary from file
  # echo "dictionary check"
  # for word in "${wordlist[@]}"; do  echo "key:${word}  value: " ${dictionary["${word}"]}; done 

  outputstring="${inputstring}"
  for word in "${wordlist[@]}"; do  
   if [ -z ${dictionary["${word}"]} ]; then 
    result+=";0"
   else
    #match
   
   #outputstring=$(echo "${outputstring//${word}/<mark>${word}</mark>}")
    result+=";${dictionary["${word}"]}" 
    matches=$((${matches} + ${dictionary["${word}"]}))
    
   fi
  done 
  
  for word_za in "${wordlistreverse[@]}"; do
    outputstring=$(echo "${outputstring//${word_za}/<mark>${word_za}</mark>}")
  done

  if [ ${matches} -gt ${total} ]; then
   echo "Error matches (${matches}) greater total (${total}) words ";
    for test in "${wordlist[@]}" ; do  echo ":: ${test} : ${dictionary[${test}]}";  done;
    exit 1 ;
  fi
  
  if [ ${total} != 0 ]; then 
   ratio=$(printf %.10f\\n "$((1000000000 * ${matches} / ${total} ))e-9");
  fi

  echo "${outputstring}"  >> "${htmlout}"
  
  # write content to csv
  echo '"'"${files[$i]}"'"'";${total};${matches};${ratio/,/.}${result}"    >> "${output}"
 fi
done

echo "${html_end}" >> "${htmlout}"
