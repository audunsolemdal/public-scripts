$workspaceName = "cp-repos"
$json = Get-Content ./$workspaceName.code-workspace | ConvertFrom-Json

$jwt = "ghs_xxx"

$repoListTest = @(
    "wl-testteam1"
    "wl-tstsp1"
)

$branch = "bump-tflint"

function Checkout {
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
    git -C $folder commit -m "Updated reference for multiple repos"

}

function Push {
    git -C $folder push
}

function New-PR {
    gh api `
        --method POST `
        -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer $jwt" `
        "/repos/miljodir/$folder/pulls" `
        -f title='Automated multi-repo update: Update AzureRM tflint version to latest available' `
        -f body='Please review the changes and approve if everything seems alright' `
        -f head=$branch `
        -f base='main' 
}

function Approve {
    cd $folder
    gh pr review --approve -b "Automated approval, please double check tfplan before merging"
    cd -
}

function Merge {
    cd $folder
    gh pr merge --admin --merge
    cd -
}

foreach ($folder in $($json.folders.path)) {
    # foreach ($folder in $repoListTest) {
    Reset
    #Checkout
    #Commit
    #Push
    
    #New-PR
    #Approve
    #Merge

}