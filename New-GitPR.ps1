$workspaceName = "wl-repos"
$json = Get-Content ./$workspaceName.code-workspace | ConvertFrom-Json

$jwt = "fetch me from github app auth"

function Checkout {
    $branch = "feature2"
    git -C $folder checkout -b $branch
}

function Commit {
    git -C $folder add *.tf
    git -C $folder commit -m "Updated reference for multiple repos"
}

function Push {
    git -C $folder push
}

foreach ($folder in $($json.folders.path)) {
    Checkout
    Commit
    Push

    gh api `
        --method POST `
        -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer $jwt" `
        "/repos/miljodir/$folder/pulls" `
        -f title='Apply naming standard convention' `
        -f body='whatisit' `
        -f head=$branch `
        -f base='main' 
}