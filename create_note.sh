set -e;

existingTreeSha=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -s \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/refs/$1/commits" | jq '.object.sha' -r)

if [[ $existingTreeSha == "null" ]]; then
  treeSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/trees" \
        -d '{"tree":[{"mode": "100644", "path": "'"${GITHUB_SHA}"'", "content": "'"$(base64 -w0 coverage.txt)"'"}]}' | jq '.sha' -r)
  if [[ $treeSha == "null" ]]; then
    echo "failed to create new content tree"
    exit 1
  fi
  curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/refs" \
        -d '{"ref":"refs/'"$1"'/commits","sha":"'"123${treeSha}"'"}'
else
  treeSha=$(curl -L \
        -X POST \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/trees" \
        -d '{"tree":[{"mode": "100644", "path": "'"${GITHUB_SHA}"'", "content": "'"$(base64 -w0 coverage.txt)"'"}], "base_tree": "'"$existingTreeSha"'"}' | jq '.sha' -r)
  if [[ $treeSha == "null" ]]; then
    echo "failed to create new content tree from $existingTreeSha"
    exit 1
  fi
  curl -L \
        -X PATCH \
        --fail \
        -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/refs/$1/commits" \
        -d '{"sha":"'"${treeSha}"'"}'
fi
