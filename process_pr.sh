set -e;

prJson=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -s \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/$1")

baseCommit=$(echo "$prJson" | jq '.base.sha')
headCommit=$(echo "$prJson" | jq '.head.sha')

echo "Base: $(curl https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${baseCommit}?ref=refs/notes/{$2} | jq '.content')"