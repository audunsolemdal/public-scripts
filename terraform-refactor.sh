  #!/usr/bin/env bash
# Credit to Jonathan Share
# https://blog.sharebear.co.uk/2022/05/bulk-renaming-terraform-resources/  
  set -e
  
  #REPOS=$(cat ./cp-repos.code-workspace | jq -r '.folders[].path')
  REPOS=$1
  setRandom=RANDOM
for folder in $REPOS
do
  SEARCH_FOLDER=./$folder/$2
  branchName=tf-naming-convention$setRandom

  # git -C $folder stash
  # git -C $folder reset --hard
  # git -C $folder clean -fd
  # git -C $folder pull
  # git -C $folder checkout -b $branchName

  # Generate moved blocks for resources
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^resource "' \
      | \
        awk \
          --field-separator=\" \
          '$4 ~ "-" { printf "moved {\n  from = %s.%s\n  to   = %s.%s\n}\n\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
          > \
            $SEARCH_FOLDER/refactoring.tf-soon
  
  # Generate moved blocks for data sources
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^data "' \
      | \
        awk \
          --field-separator=\" \
          '$4 ~ "-" { printf "moved {\n  from = data.%s.%s\n  to   = data.%s.%s\n}\n\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
          >> \
            $SEARCH_FOLDER/refactoring.tf-soon
  
  # Generate moved blocks for modules
  find \
      $SEARCH_FOLDER \
      -name "*.tf" \
      -print0 \
      |
        xargs \
          --null \
          grep '^module "' \
        | \
          awk \
            --field-separator=\" \
            '$2 ~ "-" { printf "moved {\n  from = module.%s\n  to   = module.%s\n}\n\n", $2, gensub("-", "_", "g", $2) }' \
            >> \
              $SEARCH_FOLDER/refactoring.tf-soon
  
  # Generate sed for resource usage
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^resource "' \
        | \
          awk \
            --field-separator=\" \
            '$4 ~ "-" { printf "s/%s\\.%s/%s.%s/g\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
            > \
              $SEARCH_FOLDER/refactoring.sed
  
  # Generate sed for resource definition
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^resource "' \
        | \
          awk \
            --field-separator=\" \
            '$4 ~ "-" { printf "s/resource \"%s\" \"%s\"/resource \"%s\" \"%s\"/g\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
            >> \
              $SEARCH_FOLDER/refactoring.sed
  
  # Generate sed for data source usage
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^data "' \
        | \
          awk \
            --field-separator=\" \
            '$4 ~ "-" { printf "s/data\\.%s\\.%s/data.%s.%s/g\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
            >> \
              $SEARCH_FOLDER/refactoring.sed
  
  # Generate sed for data source definition
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^data "' \
        | \
          awk \
            --field-separator=\" \
            '$4 ~ "-" { printf "s/data \"%s\" \"%s\"/data \"%s\" \"%s\"/g\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
            >> \
              $SEARCH_FOLDER/refactoring.sed
  
  # Generate sed for module usage
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^module "' \
        | \
          awk \
            --field-separator=\" \
            '$2 ~ "-" { printf "s/module\\.%s/module.%s/g\n", $2, $4, $2, gensub("-", "_", "g", $4) }' \
            >> \
              $SEARCH_FOLDER/refactoring.sed
  
  # Generate sed for module definition
  find \
    $SEARCH_FOLDER \
    -name "*.tf" \
    -print0 \
    | \
      xargs \
        --null \
        grep '^module "' \
        | \
          awk \
            --field-separator=\" \
            '$2 ~ "-" { printf "s/module \"%s\"/module \"%s\"/g\n", $2, gensub("-", "_", "g", $2) }' \
            >> \
              $SEARCH_FOLDER/refactoring.sed
  
  # Apply sed script
  find $SEARCH_FOLDER -name "*.tf" -print0 | xargs --null sed -i -f $SEARCH_FOLDER/refactoring.sed
  
  # Rename refactoring.tf to correct name
  mv \
    $SEARCH_FOLDER/refactoring.tf-soon \
    $SEARCH_FOLDER/refactoring.tf 

  #git -C $folder add *.tf
    
done