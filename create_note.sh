curl --request PUT \
  --url "https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${GITHUB_SHA}" \
  --header "authorization: Bearer ${GITHUB_TOKEN}" \
  --header 'content-type: application/json' \
  --fail \
  --data '{
    "message": "Coverage notes '"${GITHUB_SHA}"'",
    "content": "'"$(cat coverage.txt | base64)"'",
    "committer": {"name": "Coverage Notes", "email": "sukolenvo+cn@gmail.com"},
    "branch: "refs/$1/commits"
    }'
