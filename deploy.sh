#!/bin/bash

PROJECT=""
DEST=""
BASE_URL="git@github.com:"
UPDATE=0
CURRENT_DIR=$(pwd)
KEY="https://github.com/bcodesido.gpg"
EXPECTED="4EEB29E6302683DAE604DB9A43B7043F78302339"
EXPECTED_="0CA5791C49C9BA9C85EC53EC307E18F7DC0D4A1A"

quit() {
    cd $CURRENT_DIR
    if [ $1 -eq 1 ]; then
        echo "ERROR: "$2
    else
        echo $2
    fi
    exit $1
}

project(){
    case "$1" in
        powpeg-node )
            BASE_URL=$BASE_URL"rootstock/powpeg-node-setup"
            ;;
        token-bridge )
            BASE_URL=$BASE_URL"rsksmart/tokenbridge"
            ;;
        rskj )
            BASE_URL=$BASE_URL"rsksmart/rskj"
            ;;
        *)
            quit 1 "Project does not exists"
            ;;
    esac
}

valid_repo(){
    echo "Validating repository in destination ..."
    CURRENT_REPO_URL=$(git config --get remote.origin.url)
    if [ "$BASE_URL" = "$CURRENT_REPO_URL" ]; then
        echo "Repository Validated."
        return 0
    fi
    return 1
}

download_pubkey(){
    echo "Downloading Signature ..."
    gpg --keyserver $KEY --recv-keys $EXPECTED &&
        echo "Signature donwloaded and verified" &&
        return 0
    quit 1 "A problem ocurred downloading the gpg key. Please verify"
}

verify_tag(){
    echo "Verifing tags ... "
    LATEST_TAG=$(git describe --abbrev=0)
    RESULT=$?
    if [ $RESULT -eq 0 ] && [[ "${LATEST_TAG}" =~ ^[A-Za-z0-9.\-]+$ ]]; then
        VALID=$(git verify-tag --raw "$LATEST_TAG" 2>&1 | grep VALIDSIG |awk '{print $12}' | grep -c $EXPECTED_)
        if [ $VALID -eq 1 ]; then
            echo "Tag verified"
            echo "Moving into tag ..."
            git config advice.detachedHead false > /dev/null 2>&1
            git checkout $LATEST_TAG &&
                return 0
            quit 1 "Was not possible to checkout the $LATEST_TAG"
        fi
        quit 1 "The tag $LATEST_TAG was not verified"
    fi
    quit 1 "There are not tags in the repository"
}

while (( "$#" )); do
    case "$1" in
        -P|--project)
            PROJECT=$2
            shift 2
            ;;
        -d|--destination)
            DEST=$2
            shift 2
            ;;
        -h|--help)
            echo "Help" >&2
            quit 0
            ;;
        *)
            echo $#
            quit 1
            ;;
    esac
done


if [ -z "${PROJECT}" ] || [ -z "${DEST}" ]; then
    quit 1 "Project or Destination are empty, please check it."
fi

project $PROJECT
download_pubkey

if [ -d $DEST ]; then
    if git -C $DEST rev-parse > /dev/null 2>&1 ; then
        UPDATE=1
    fi
    if [ $UPDATE -eq 1 ]; then
        echo "Entering in update mode"
        cd $DEST
        if valid_repo ; then
            git fetch --tags
            verify_tag
        else
            quit 1 "Invalid repository in directory $DEST for project $PROJECT"
        fi
    fi
fi

if [ $UPDATE -eq 0 ]; then
    echo "Entering in install mode"
    mkdir -p $DEST &&
        echo "Cloning repo ..." &&
        git clone $BASE_URL $DEST > /dev/null 2>&1 &&
        cd $DEST &&
        verify_tag &&
        quit 0 "Ready to rumble"
    quit 1 "It wasn't possible to create the destination directory. Please remove the existing directory and try again."
fi
