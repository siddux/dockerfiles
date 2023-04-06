#!/bin/bash

# Define the Dockerfile extension we're looking for
DOCKERFILE_EXTENSION=".Dockerfile"

# Define the Dockerhub repo
DOCKERFILE_REPO="siddux/ros"

# Define the name of the file that contains the tags
TAG_FILE="tags.txt"

# Get the current date in YYYY-MM-DD format
DATE=$(date +%Y-%m-%d)

# Define variables to store command-line arguments
DIRECTORY=""
FILES=""
SKIP_FILES=""
UPLOAD=false

# Function to display usage instructions
function show_help {
  echo "Usage: $0 [-d DIRECTORY | --dir DIRECTORY] [-f FILE1,FILE2,... | --file FILE1,FILE2,...] [-s SKIP1,SKIP2,... | --skip SKIP1,SKIP2,...] [-u | --upload] [-h]"
  echo "Build Docker images from Dockerfiles in a directory with tags from a tag file"
  echo ""
  echo "Options:"
  echo "  -d, --dir DIRECTORY   Specify the directory containing the Dockerfiles"
  echo "  -f, --file FILE1,FILE2,...  Specify a comma-separated list of filenames to process"
  echo "  -s, --skip SKIP1,SKIP2,...  Specify a comma-separated list of filenames to skip"
  echo "  -u, --upload          Upload the built Docker images to Dockerhub"
  echo "  -h, --help            Show this help message and exit"
  echo ""
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -d|--dir) DIRECTORY="$2"; shift ;;
    -f|--file) FILES="$2"; shift ;;
    -s|--skip) SKIP_FILES="$2"; shift ;;
    -u|--upload) UPLOAD=true ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Invalid option: $1. Use -h or --help for usage instructions"; exit 1 ;;
  esac
  shift
done

# Check if the directory argument was provided
if [ -z "$DIRECTORY" ]; then
  echo "Error: directory argument not provided"
  exit 1
fi

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
  echo "Error: directory does not exist"
  exit 1
fi

# Check if the directory is empty
if [ -z "$(ls -A $DIRECTORY)" ]; then
  echo "Directory is empty, skipping images"
  exit 0
fi

# Check if the tags file exists
if [ ! -f "$DIRECTORY/../$TAG_FILE" ]; then
    echo "Error: tags file does not exist"
    exit 1
fi

# Loop through each Dockerfile in the directory
for FILE in $DIRECTORY/*$DOCKERFILE_EXTENSION; do
    # Get the filename without the extension
    NAME=$(basename "$FILE" "$DOCKERFILE_EXTENSION")
    # Check if the file is included in the list of files to skip
    if [[ -n "$SKIP_FILES" && $SKIP_FILES =~ (^|[[:space:]])"$NAME"($|[[:space:]]) ]]; then
        # Skip this file if it's in the list of files to skip
        continue
    fi
    # Check if the file is included in the list of files to process
    if [[ -n "$FILES" && ! $FILES =~ (^|[[:space:]])"$NAME"($|[[:space:]]) ]]; then
        # Skip this file if it's not in the list of files to process
        continue
    fi
    # Loop through each tag in the tag file
    while read TAG; do
        # Build the Docker image using the current file, tag, and date
        docker build -f $FILE --target $TAG -t $DOCKERFILE_REPO:$NAME-$TAG -t $DOCKERFILE_REPO:$NAME-$TAG-$DATE .
    done < $DIRECTORY/../$TAG_FILE
done

echo "Done: all images have been built correctly!"

if [ "$UPLOAD" = true ]; then
  docker push -a $DOCKERFILE_REPO
  echo "Done: all images have been uploades succesfully!"
fi
