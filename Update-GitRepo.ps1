<#
    .DESCRIPTION
        Utility to update multiple repos at once. Requries that you have a vscode workspace installed,
        and that your changes are saved by using the search and replace functionality in vscode before running
        the script.
#>

param (
    [string]$workspaceName = "cp-repos",
    [string]$branchName = "tf-naming-convention$(Get-Random -Maximum 400)",
    [string]$prTitle = "Automated multi-repo update",
    [string]$prBody = "Automated change - please review the changed files"
)

$json = Get-Content ./$workspaceName.code-workspace | ConvertFrom-Json

$repoListTest = @(
    "wl-testteam1"
    "flux-team1"
)
$prList = @()
$failedList = @()

function Checkout {
    param (
        $folder
    )
    try {
        git -C $folder checkout main
        git -C $folder pull
        git -C $folder checkout -b $branchName
    }
    catch {
        git -C $folder checkout main
        git -C $folder pull
        git -C $folder checkout $branchName
    }
}

function Commit {
    git -C $folder add .
    git -C $folder commit -m "Updated reference for multiple repos"
}

function Push {
    git -C $folder push
}

foreach ($folder in $($json.folders.path)) {
    #foreach ($folder in $($repoListTest)) {
    
    #Checkout $folder

    if ($?) {
        Commit
    }
    else {
        $failedList += $folder
        break
    }

    if ($? -and $branch -ne "main" -and $branch -ne "production" && $branch -ne "master" ) {
        Push

        if ($?) {
            Set-Location $folder
            $pr = gh pr create -b $branchName --title $prTitle --body $prBody
            $prList += $pr
            Set-Location -
        }
        else {
            $failedList += $folder
            break
        }
    }
    else {
        Write-Output "Failed to auto-commit on branch $branchName for repo $folder ..."
    }
}

$prList | Set-Clipboard

Write-Host "Failed PRs or commits:"
$failedList

Write-Host "Created PRs:"
$prList