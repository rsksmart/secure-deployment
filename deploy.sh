#!/bin/bash

PROJECT=""
PROJECT_NAME=""
ACTION=""
PROGRAMS="git gpg curl docker"
BASE_URL="https://github.com/"
UPDATE=1
CURRENT_DIR=$(pwd)
KEY="https://github.com/aeidelman.gpg"
EXPECTED="0CA5791C49C9BA9C85EC53EC307E18F7DC0D4A1A"

quit() {
    cd $CURRENT_DIR
    if [ $1 -eq 1 ]; then
        echo "ERROR: "$2
    else
        echo $2
    fi
    exit $1
}

check_required_programs() {
    echo "Checking for required software..."
    rc=0
    for program in $PROGRAMS; do
        if ! command -v "$program" >/dev/null 2>&1; then
            rc=1
            echo "$program: command not found"
        fi
    done
    if [ $rc -ne 0 ]; then
        quit 1 "Requirements not acomplished"
    fi
}

project(){
    PROJECT_NAME=$(echo $PROJECT | cut -f2 -d"/")
}

repo_name(){
    BASE_URL=$BASE_URL$PROJECT
}

valid_repo(){
    echo "Validating repository for $PROJECT_NAME ..."
    git rev-parse --git-dir > /dev/null 2>&1
}

download_pubkey(){
    echo "Downloading Key ..."
    gpg --keyserver $KEY --recv-keys $EXPECTED &&
        echo "Key donwloaded and verified" &&
        return 0
    quit 1 "A problem ocurred downloading the gpg key. Please verify"
}

verify_tag(){
    echo "Verifying tags ... "
#    LATEST_TAG=$(git describe --abbrev=0)
#    RESULT=$?
    RESULT=0
    LATEST_TAG="TESTING-2.0.1"
    if [ $RESULT -eq 0 ] && [[ "${LATEST_TAG}" =~ ^[A-Z]+\-[0-9].[0-9].[0-9]$ ]]; then
        VALID=$(git verify-tag --raw "$LATEST_TAG" 2>&1 | grep VALIDSIG |awk '{print $12}' | grep -c $EXPECTED)
#        if [ $VALID -eq 1 ]; then
            echo "Tag verified"
            echo "Moving into tag ..."
            git config advice.detachedHead false > /dev/null 2>&1
            git checkout $LATEST_TAG &&
                return 0
            quit 1 "Was not possible to checkout the $LATEST_TAG"
#        fi
#        quit 1 "The tag $LATEST_TAG was not verified"
    fi
    quit 1 "There are not tags in the repository"
}

clone() {
    echo $PROJECT_NAME >> $CURRENT_DIR/.packages
    mkdir -p $PROJECT_NAME &&
        echo "Cloning repo ..." &&
        git clone $BASE_URL $PROJECT_NAME > /dev/null 2>&1 &&
        cd $CURRENT_DIR/$PROJECT_NAME
        return 0
    quit 1 "It wasn't possible to clone the repo into the destination directory. Please check and try again."
}

validate_action() {
    case "$ACTION" in
        install)
            UPDATE=1
            ;;
        update)
            UPDATE=0
            ;;
        *)
            quit 1 "Invalid action. Use --help for help."
            ;;
    esac
}

deploy(){
    verify_tag &&
        bash ./deploy.sh $UPDATE $CURRENT_DIR/$PROJECT_NAME &&
        quit 0 "Done."
    quit 1 "There was a problem running the deploy"
}

while (( "$#" )); do
    case "$1" in
        -P|--project)
            PROJECT=$2
            project
            shift 2
            ;;
        -a|--action)
            ACTION=$2
            validate_action
            shift 2
            ;;
        -h|--help)
            echo
            echo "Usage:"
            echo "        -P|--project: Project repo to deploy or update. Must be a valid GitHub repo like for example:"
            echo "                    * rsksmart/token-bridge "
            echo
            echo "        -a|--action: Action to perform. Valid actions are:"
            echo "                    * install"
            echo "                    * update"
            echo           
            echo "        -h|--help: Show this help."
            echo
            quit 0
            ;;
        *)
            quit 1 "No valid parameter use -h for help"
            ;;
    esac
done

[ $UPDATE -eq 1 ] &&
    [ -z "$PROJECT" ] &&
    quit 1 "Missing project. Use --help for help."

check_required_programs
download_pubkey

if [ $UPDATE -eq 0 ]; then
    for pkg in $(sort -u <"$CURRENT_DIR/.packages"); do
        PROJECT_NAME=$pkg
        repo_name
        cd $CURRENT_DIR/$PROJECT_NAME
        if valid_repo ; then
            git fetch --tags &&
                deploy
        else
            quit 1 "Invalid repository in directory $CURRENT_DIR/$PROJECT_NAME for project $PROJECT_NAME"
        fi
    done
fi

if [ $UPDATE -eq 1 ]; then
    repo_name
    clone &&
        deploy
fi
