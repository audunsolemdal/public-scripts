$workspaceName = "wl-repos"
$json = Get-Content ./$workspaceName.code-workspace | ConvertFrom-Json

$env:jwt = (node ./my-iac/authapp/app.js | ConvertFrom-Json | Select-Object token -ExpandProperty token)

$repoListTest = @(
    #"wl-testteam1"
    #"wl-tstsp1"
)

#$branch = "cleahnup-kv"
$branch = "cleanup-current-kv-access2"

function CheckoutNew {
    git -C $folder checkout -b $branch
}

function Reset {
    git -C $folder reset --hard
    git -C $folder clean -fd
    git -C $folder checkout main
    git -C $folder pull
}

function Commit {
    git -C $folder add .
    git -C $folder commit -m "Cleanup personal and owners kv accesses"

}

function CommitEmpty {
    git -C $folder commit --allow-empty -m "Empty commit to retrigger TF Plan"

}

function PullCurrent {
    git -C $folder branch --set-upstream-to="origin/$(git -C $folder branch --show-current)" (git -C $folder branch --show-current) && git -C $folder pull
}

function Push {
    git -C $folder push
}

function New-PR {
    gh api `
        --method POST `
        -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer $env:jwt" `
        "/repos/miljodir/$folder/pulls" `
        -f title='Multi-repo update: Remove .current, personal and owner groups access to keyvault' `
        -f body='Please review the changes and approve if everything seems alright. Access to manage these things should be done through AAD groups. Note the following: - access to current.user or Owners group is now granted through terraform for simplicity. - The removal of the `current` user access is replaced by the assignment occuring in the cp-yggdrasil repo.  - In 90% of cases, access to manage secrets will be sufficient, hence the lack of key/certificate rbac assignments' `
        -f head=$branch `
        -f base='main' 
}

function Patch-PR {

    cd $folder
    $prNumber = gh pr list --head (git branch --show-current) --json number --jq .[].number
    cd -

    gh api `
        --method PATCH `
        -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer $env:jwt" `
        "/repos/miljodir/$folder/pulls/$prNumber" `
        -f title='Multi-repo update: Remove personal and owner groups access to key vault in test environment' `
        -f body='Please review the changes and approve if everything seems alright. Access to manage these things should be done through AAD groups. Note the following: - access to current.user or Owners group is now granted through terraform for simplicity, access will be granted to the contributor group  - The removal of the `current` user access is replaced by the assignment occuring in the cp-yggdrasil repo.  - In 90% of cases, access to manage secrets will be sufficient, hence the lack of key/certificate rbac assignments' `
        -f head=$branch `
        -f base='main' 
}

function Approve {
    cd $folder
    gh pr review --approve -b "Automated approval, please double check changes and TF Plan before merging. Do not merge before Monday/Tuesday to wait for complaints from dev envs"
    cd -
}

function Merge {
    cd $folder
    gh pr merge --admin --merge
    cd -
}

# The below functions are useful if you make mistakes and need to cleanup the PR / branches

function MergeMain {
    git -C $folder merge main
}

function RemoveConflict {
    git -C $folder rm platform/dev/README.md
    git -C $folder rm platform/dev/.terraform.lock.hcl
}

function CheckoutExisting {
    git -C $folder checkout $branch
}

function Reset1 {
    git -C $folder reset head~1
    git -C $folder stash
    git -C $folder checkout main
    git -C $folder pull
}

function Pop {
    git -C $folder checkout -b $branch
    git -C $folder pop
}

function Difference {
    $compare = (git -C $folder rev-parse head main)

    if ($compare[0] -eq $compare[1]) {
        return $false
    }
    else {
        return $true
    }
}

# foreach ($folder in $($json.folders.path)) {
#     Reset
#     CheckoutNew
# }

# foreach ($folder in $($json.folders.path)) {
#     Commit
#     Push
# }


# foreach ($folder in $($json.folders.path)) {
#     Commit
#     $diff = Difference

#     if ($diff) {
#         push
#         New-PR
#     }
#     else {
#         Write-Host "No changes detected for repo $folder..."
#     }
# }

# foreach ($folder in $($json.folders.path)) {
#     #Push
#     Reset1
#     Reset
#     CheckoutExisting
#     PullCurrent
#     #Push
# }

# foreach ($folder in $($json.folders.path)) {
#     CommitEmpty
#     Push
# }


foreach ($folder in $($json.folders.path)) {
    $diff = Difference

    if ($diff) {
        Write-Host "Found diff in $folder"
        Approve
        #Merge
    }
    else {
        Write-Host "No changes detected for repo $folder"
    }
}