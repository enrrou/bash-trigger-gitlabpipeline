#!/bin/bash
set -x


project=$1
branch=$2
tokenuser=$3
# tokenpipeline=$3
gitlaburl=gitlab.com


datefile=`date '+%d%m%y%H%M%S'`
tmpfile="/tmp/gitlabtrigger_pipeline_$datefile.tmp"
tmpprojectsfile="/tmp/gitlabtrigger_projects_$datefile.tmp"

# check arg help
if [[ $# -eq 0 ]] ; then
    echo 'Usage : bin project branch'
    echo 'Example : bin transfert master'
    exit 0
fi

function get_projects() {
    echo "------------------------------------------------"
    echo " Get Gitlab Projects"
    echo "------------------------------------------------"
    echo ""

    curl -X GET --header "PRIVATE-TOKEN: $tokenuser" -s https://$gitlaburl/api/v4/projects/ | jq . > $tmpprojectsfile
}

function get_project_id() {
    echo "------------------------------------------------"
    echo " Get Gitlab project pipelines"
    echo "------------------------------------------------"
    echo ""

    project_id=`curl --header "PRIVATE-TOKEN: $tokenuser" -s https://$gitlaburl/api/v4/projects?search=$project | jq -r '.[].id'`

    echo $project_id
}

function run_pipeline (){
    echo "------------------------------------------------"
    echo " Gitlab pipeline id=$project_id"
    echo "------------------------------------------------"
    echo ""

    echo "Trigger Gitlab pipeline job for project $projects"
    curl -X POST  -F token="$tokenuser"  -F ref=master -s  https://$gitlaburl/api/v4/projects/$projects/trigger/pipeline | jq . > $tmpfile

    id=`jq -r '.id' $tmpfile`
    url=`jq -r '.web_url' $tmpfile`
    echo "Gitlab job id : $id"
    echo "Gitlab job url : $url"
    echo ""

    until [ $(curl --header "PRIVATE-TOKEN: $tokenuser"  -s https://$gitlaburl/api/v4/projects/$projects/pipelines/$id | jq -r .status) = "success" ]; do
    echo "pipeline is running, please wait  ..."
    sleep 2
    done

    rm -f $tmpfile
    echo ""
    echo "Deployment complete"
    echo "Success ! " 
}

function run_prod_pipeline() {
    echo "------------------------------------------------"
    echo " Gitlab pipeline id=$project_id"
    echo " Deploy to $branch"
    echo "------------------------------------------------"
    echo ""

    curl -X POST --header "PRIVATE-TOKEN: $tokenuser" -s "https://$gitlaburl/api/v4/projects/$project_id/trigger/pipeline?ref=prod" | jq . > $tmpfile
    echo "Pipeline started on branch $branch"


    cat $tmpfile
    #get job_id

    # running_pipeline = `curl -X GET  -F token="$tokenuser" -s 'https://$gitlaburl/api/v4/projects/$projects/pipelines/pipelines?status=running' | jq -r '.[].id'`
    # until [ $(curl --header "PRIVATE-TOKEN: $tokenuser"  -s https://$gitlaburl/api/v4/projects/$projects/pipelines/$id | jq -r .status) = "success" ]

    # echo "Build complete"
    # echo "Now need to run manual deploy"
}

if [[ $branch == prod ]] ; then
    get_project_id
    run_prod_pipeline
fi



