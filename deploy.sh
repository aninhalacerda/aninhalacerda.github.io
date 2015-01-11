#!/bin/bash

function dirty_check {
  if [[ `(git status --porcelain 2> /dev/null) && (git log origin/master..master 2> /dev/null)` &&  -z "$1" ]]; then
    echo
    echo "# You have changes that were not pushed to master yet."
    echo
    exit -1
  fi
}

function create_gh_pages {
  [[ `git ls-remote origin | grep gh-pages` ]] && return
  TMP="/tmp/$(LC_CTYPE=C tr -dc 0-9 < /dev/urandom | head -c 20 | xargs | cat)"
  rsync -qa .git $TMP
  pushd $TMP
    git checkout --orphan gh-pages
    git pull origin gh-pages
    git rm -qrf .
    git commit -qam "" --allow-empty --allow-empty-message
    git push origin gh-pages
  popd
  rm -rf $TMP
}

function dist {
  DIST_DIR=$(awk '/destination:/{dist=$2}; END {if (dist) print dist; else print "./_site"}' < _config.yml)
  if [[ ! -d $DIST_DIR/.git ]]; then
    REMOTE_ORIGIN=$(git remote -v | awk '/origin/{print $2}' | sort -u)
    rm -rf $DIST_DIR

    git clone \
      --single-branch \
      --branch=gh-pages \
      --depth=1 $REMOTE_ORIGIN \
      $DIST_DIR
  fi
  time bundle exec jekyll build
}

function deploy {
  DIST_DIR=$(awk '/destination:/{dist=$2}; END {if (dist) print dist; else print "./_site"}' _config.yml)
  MASTER_HEAD_SHA=$(git rev-parse --short HEAD)
  pushd $DIST_DIR
    git add . -A
    git commit -m "Deployed from master: $MASTER_HEAD_SHA"

    echo "Pushing code to branch gh-pages..."
    git push origin gh-pages
  popd
}

function install_gems {
  bundle install --jobs 8
}

install_gems $1
dirty_check $1
create_gh_pages
dist
deploy