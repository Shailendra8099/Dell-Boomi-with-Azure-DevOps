#!/bin/bash

source bin/common.sh
# get atom id of the by atom name
# mandatory arguments
ARGUMENTS=(extensionJson)
OPT_ARGUMENTS=(envId env)
id=result[0].id

inputs "$@"

if [ "$?" -gt "0" ]
then
        return 255;
fi

if [ ! -z "${envId}" ]
	then
		envId=${envId}
elif [ ! -z "${env}" ]
	then
		source bin/queryEnvironment.sh env=${env} type="*" classification="*"
else
		envId=$(echo "$extensionJson" | jq -r .environmentId)
fi

echov "The env id is ${envId}"

TMP_JSON_FILE="${WORKSPACE}"/tmpExtension.json
JSON_FILE="${WORKSPACE}"/tmp.json

echo $extensionJson | jq --arg envId $envId '.environmentId=$envId' | jq --arg envId $envId '.id=$envId' > "$TMP_JSON_FILE"
echo "" > "${JSON_FILE}"


while IFS= read -r line
 do
        if [[ "$line" == *"valueFrom"* ]]
        then
                valueText=$(echo "$line" | sed -e 's/\"//g' -e 's/,//g' -e 's/^.*:\s\+//' -e 's/\s+.*$//g')
                echov $valueText
                getValueFrom "${valueText}"
                echo "$line" | sed -e "s/$valueText/$extensionValue/" -e 's/valueFrom/value/' >> "${JSON_FILE}"
        else
                echo "$line" >> "${JSON_FILE}"
        fi
 done < "$TMP_JSON_FILE"

URL=$baseURL/EnvironmentExtensions/${envId}/update
 
callAPI
 
clean

if [ "$ERROR" -gt "0" ]
then
   return 255;
fi
