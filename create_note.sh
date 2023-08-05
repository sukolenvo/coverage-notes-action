set -e;

ref="refs/notes/$1"

commitSha=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -s \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/$ref" | jq '.object.sha' -r)

if [[ "$commitSha" == "null" ]]; then
  echo "Ref $ref doesn't exist"
  treeSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/trees" \
        -d '{"tree":[{"mode": "100644", "path": "'"${GITHUB_SHA}"'", "content": "'"$(cat coverage.txt)"'"}]}' | jq '.sha' -r)
  if [[ $treeSha == "null" ]]; then
    echo "failed to create new content tree"
    exit 1
  fi
  echo "Created new content tree $treeSha"
  newCommitSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/commits" \
        -d '{"message": "save coverage details", "author": {"name": "Coverage notes bot", "email": "sukolenvo+cn@gmail.com"}, "tree":"'"$treeSha"'"}'| jq '.sha' -r)
  curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/refs" \
        -d '{"ref":"'"$ref"'","sha":"'"${newCommitSha}"'"}'
  echo "Updated ref $ref to the new content tree"
else
  echo "Found existing ref $ref. Commit sha: $commitSha"
  existingTreeSha=$(curl -L \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/commits/$commitSha" | jq '.tree .sha' -r)
  echo "Tree sha $existingTreeSha"
  treeSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/trees" \
        -d '{"tree":[{"mode": "100644", "path": "'"${GITHUB_SHA}"'", "content": "'"$(cat coverage.txt)"'"}], "base_tree": "'"$existingTreeSha"'"}' | jq '.sha' -r)
  if [[ $treeSha == "null" ]]; then
    echo "failed to create new content tree from $existingTreeSha"
    exit 1
  fi
  echo "Created new content tree $treeSha"
  newCommitSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/commits" \
        -d '{"message": "save coverage details", "author": {"name": "Coverage notes bot", "email": "sukolenvo+cn@gmail.com"}, "tree":"'"$treeSha"'"}'| jq '.sha' -r)
  curl -L \
        -X PATCH \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/$ref" \
        -d '{"sha":"'"${newCommitSha}"'"}' > /dev/null
  echo "Updated ref $ref to the new commit $newCommitSha"
fi
