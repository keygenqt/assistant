#!/bin/bash

#  ./statistic.sh -dg=/home/keygenqt/project -d=/home/keygenqt/project/app/src/main/java/me -s=".*\.kt"

# add color red
CLEAR='\033[0m'
RED='\033[0;31m'

# load arguments
for i in "$@"; do
  case $i in
  -t=* | --tag=*)
    TAG="${i#*=}"
    shift
    ;;
  -d=* | --dir=*)
    DIR="${i#*=}"
    shift
    ;;
  -dg=* | --dir-git=*)
    DIR_GIT="${i#*=}"
    shift
    ;;
  -s=* | --search=*)
    SEARCH="${i#*=}"
    shift
    ;;
  -ex=* | --exclude=*)
    EXCLUDE="${i#*=}"
    shift
    ;;
  *)
    echo -e "${RED}"Unknown parameter passed: $i"${CLEAR}"
    exit 1
    ;;
  esac
done

# check required argument
if [ -z "$DIR" ]; then
  echo -e "${RED}Dir (-d=*|--dir=*) required argument${CLEAR}"
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo -e "${RED}Dir not exist${CLEAR}"
  exit 1
fi

# check required argument
if [ -z "$SEARCH" ]; then
  echo -e "${RED}Search (-s=*|--search=*) required argument${CLEAR}"
  exit 1
fi

# set default argument
if [ -z "$EXCLUDE" ]; then
  EXCLUDE="^\/\/.*"
fi

# set default argument
if [ -z "$DIR_GIT" ]; then
  DIR_GIT="$DIR"
fi

#check .git dir
if [ ! -d "$DIR_GIT/.git" ]; then
  echo -e "${RED}$DIR_GIT/.git not found.${CLEAR}"
  exit 1
fi

# get statistic now
st=$(/snap/bin/kg-assistant --dir="$DIR" --statistic --search="$SEARCH" --exclude="$EXCLUDE" --exclude-lines=1)

# get count files
files=$(echo "$st" | sed -n 1p | sed -e "s/\s//g" | sed -e "s/countfiles\://g")

# get count lines
lines=$(echo "$st" | sed -n 2p | sed -e "s/\s//g" | sed -e "s/countlines\://g")

# copy dir for revert
cp -r "$DIR_GIT" "${DIR_GIT}_"

# open dir
cd "${DIR_GIT}_" || exit

if [ "$TAG" == "" ]; then
  # get last tag
  TAG=$(git tag -l | sort -V | tail -1)
fi

# show HEAD statistic
echo -e "${RED}HEAD statistic${CLEAR}"
echo "files: $files"
echo "code lines: $lines"

# tag not found
if [ -z "$TAG" ]; then
  exit 0
fi

# git revert to tag
git reset --hard "$TAG" --quiet

# get temp dir tag
tempDir=${DIR//${DIR_GIT}/${DIR_GIT}_}

# get statistic tag
st=$(/snap/bin/kg-assistant --dir="$tempDir" --statistic --search="$SEARCH" --exclude="$EXCLUDE" --exclude-lines=1)

# get count files
filesTag=$(echo "$st" | sed -n 1p | sed -e "s/\s//g" | sed -e "s/countfiles\://g")

# get count lines
linesTag=$(echo "$st" | sed -n 2p | sed -e "s/\s//g" | sed -e "s/countlines\://g")

# remove temp dir
rm -rf "${DIR_GIT}_"

# files count
filesCount=$((files - filesTag))

# lines count
linesCount=$((lines - linesTag))

echo ""

# show TAG statistic
echo -e "${RED}TAG statistic ($TAG)${CLEAR}"
echo "files: $filesTag"
echo "code lines: $linesTag"

echo ""

# show counting
echo -e "${RED}Counting${CLEAR}"

if [ "$filesCount" -gt "0" ]; then
  echo "files: +$filesCount"
else
  echo "files: $filesCount"
fi

if [ "$linesCount" -gt "0" ]; then
  echo "code lines: +$linesCount"
else
  echo "code lines: $linesCount"
fi

exit 0
