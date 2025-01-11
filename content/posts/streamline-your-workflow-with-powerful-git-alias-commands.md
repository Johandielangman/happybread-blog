---
author: Johan Hanekom
title: Streamline Your Git Workflow With Powerful Git Alias Commands
date: 2024-12-08
tags:
  - Git
draft: "false"
---
A while back, I learned that your `~/.gitconfig` file isn't just for setting your default `git init` branch. You can also define [aliases](https://git-scm.com/docs/git-config#Documentation/git-config.txt-alias)! Git aliases are powerful workflow tools that let you create shortcuts for frequently used Git commands. This seemed like the perfect opportunity to define some useful workflow enhancements.

## Listing Most Recently Accessed Branches Using _git lb_

I quickly turned to Google in search of an alias for something I'd always wanted in Git: _What are the most recent branches I've been working on?_ While [`git checkout -`](https://git-scm.com/docs/git-checkout) works well to toggle between the last two branches, it falls short when you need to juggle three or more. I addition, the branches I work on a daily basis are auto-generated and not easy to remember. This functionality was a natural candidate for an alias. Having this information directly in my terminal would be amazing

Enter my favorite alias: `git lb`. Running this command lists your most recent branches, complete with color-coded output for clarity.

```console
foo@bar:~/my-awesome-repo$ git lb
  31 minutes ago: fun-branch
  2 days ago: remove-things
  3 days ago: staging
  6 days ago: remove-bugs
  7 days ago: add-bugs
  7 days ago: master
  2 days ago: dev
  3 weeks ago: enhance_something
  3 weeks ago: hotfix-1
  4 weeks ago: undo-mess
```

Isn’t this the best? I use this alias more than any other. Here's how it's configured:

```bash
[alias]
    lb = !git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep 'checkout:' | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | head -n 10 | awk -F' ~ HEAD@{' '{printf(\"  \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'
```

Credit goes to [Scott Stafford](https://ses4j.github.io/2020/04/01/git-alias-recent-branches/) for sharing this beautifully crafted alias, which he built on insights from a [Stack Overflow](https://stackoverflow.com/questions/40291034/how-to-find-the-last-branch-checked-out-in-git) discussion. Stafford also provided an excellent breakdown of how the alias works:

- [`git reflog`](https://git-scm.com/docs/git-reflog) `show --pretty=format:'%gs ~ %gd' --date=relative`: Fetches the raw data we need. Try it out to see the unformatted output.
- `grep 'checkout:'`: Filters out lines unrelated to branch checkouts.
- `grep -oE '[^ ]+ ~ .*'`: Extracts (`-o`) only the relevant part of each line.
- `awk -F~ '!seen[$1]++'`: Splits fields (`-F`) on `~`. Tracks each unique branch name in an array and skips duplicates.
- `head -n 10`: Limits the output to the 10 most recent branches.
- `awk -F' ~ HEAD@{' '{printf(\" \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'`: Adds pretty ANSI color formatting and cleans up the output.

Inspired by this approach, I plan to follow his example for creating my own aliases in the rest of the blog.

## Commit history using *git structure* and *git s20*

To view the commit history, I wanted an alias that would provide a clear and structured view, including the SHA hashes for easy use with commands like [`git cherry-pick`](https://git-scm.com/docs/git-cherry-pick). Additionally, I wanted it to display the commits in an ASCII tree structure, helping me visualize the flow of commits and merges. Here’s an example of using `git structure` on one of my projects:

```console
foo@bar:~/my-awesome-repo$ git structure
*   24568c8 (HEAD -> main, tag: v1.1.0, origin/main, origin/HEAD) Merge branch 'chore/initial-version'
|\
| * 77cfe2a (origin/chore/initial-version, chore/initial-version) version: alpha
* | 86f8a30 (tag: v1.0.2) Added Dev Container Folder
|/
* 7bd975f (tag: v1.0.1) version manager
* 93a4c13 (tag: v1.0.0) feat: add page configuration and menu items for enhanced user experience
* 1e4e992 Initial commit
```

In this example, you can see the project's progression, starting with the initial commit on the main branch. Subsequent commits include adding a version manager and a Dev Container folder. After these changes, I branched off to `chore/initial-version` to make some major updates. Once the work was complete, it was merged back into the main branch at commit `24568c8`. This view gives me exactly the information I need. Here's how the alias is set up:

```shell
[alias]
	structure = log --oneline --simplify-by-decoration --graph --all
```

Here’s a breakdown of what each part does:

- [`log`](https://git-scm.com/docs/git-log): The base Git command used to inspect the commit history.
- `--oneline`: Displays each commit on a single line, including the commit hash and message. This makes the output concise and easy to read.
- `--simplify-by-decoration`: Shows only commits that have references (branches or tags) pointing to them. This eliminates intermediate commits that aren't directly relevant, resulting in a cleaner view.
- `--graph`: Adds an ASCII representation of the commit graph, helping you visualize the branching and merging paths.
- `--all`: Ensures the full commit history is displayed, including all branches and tags, rather than limiting it to the current branch.

Displaying commit history in a paginated view can be inconvenient, especially for larger projects. Often, the information I need is within the top 20 commits. To address this, I created a shorter version of the `git structure` alias called `git s20`. It retains all the features of the original but limits the output to the most recent 20 commits and disables pagination. Here's an example of its use:

```console
foo@bar:~/my-awesome-repo$ git s20
*   24568c8 (HEAD -> main, tag: v1.1.0, origin/main, origin/HEAD) Merge branch 'chore/initial-version'
|\
| * 77cfe2a (origin/chore/initial-version, chore/initial-version) version: alpha
* | 86f8a30 (tag: v1.0.2) Added Dev Container Folder
|/
* 7bd975f (tag: v1.0.1) version manager
* 93a4c13 (tag: v1.0.0) feat: add page configuration and menu items for enhanced user experience
* 1e4e992 Initial commit
```

Here’s how the alias is configured:

```shell
[alias]
	s20 = !git --no-pager log -20 --oneline --simplify-by-decoration --graph --all
```

Here's what I added:

- `--no-pager`: Prevents Git from using its pager, so the output is displayed directly in the terminal without any scrolling or buffering. Perfect for quick checks.
- `-20`: Restricts the output to the 20 most recent commits. You can modify this number to include more or fewer entries as needed.

This alias provides a concise, paginated-free view of the most recent activity, making it a convenient tool for quickly scanning commit history. Simple, effective, and straight to the point.

## Enhanced Logging with _git slog_, _git last_, and _git l20_

Sometimes, I need a clean yet informative log of my commits. Enter my new favorite aliases: `git slog`, `git last`, and `git l20`. These provide formatted views of the commit history with key details like commit hash, date, author, branch info, and commit message -- all in color-coded glory. All of them are actually similar to `git slog`. I just wanted to have a one that shows the top 20 (`git l20`) and the last one (`git last`). Here's an example output using the `git l20` variant:

```console
foo@bar:~/my-awesome-repo$ git l20
24568c8 2024-11-15 Johandielangman (HEAD -> main, tag: v1.1.0, origin/main, origin/HEAD) Merge branch 'chore/initial-version'
86f8a30 2024-11-15 Johan (tag: v1.0.2) Added Dev Container Folder
77cfe2a 2024-11-15 Johandielangman (origin/chore/initial-version, chore/initial-version) version: alpha
c65e9aa 2024-11-09 Johandielangman feat: infrastructure and ratings page
7bd975f 2024-11-09 Johandielangman (tag: v1.0.1) version manager
93a4c13 2024-11-07 Johandielangman (tag: v1.0.0) feat: add page configuration and menu items for enhanced user experience
74dd21e 2024-11-07 Johandielangman feat: add page configuration and menu items for enhanced user experience
59635f1 2024-11-07 Johandielangman refactor: simplify session management and remove cookie handling
...
```

Seeing the concise log with relevant details at a glance has made managing projects a breeze. Here’s how each logging alias works:

```bash
[alias]
    slog = log --pretty=format:'%C(auto)%h %C(red)%as %C(blue)%aN%C(auto)%d%C(green) %s'
    last = !git --no-pager log -1 --pretty=format:'%C(auto)%h %C(red)%as %C(blue)%aN%C(auto)%d%C(green) %s'
    l20 = !git --no-pager log -20 --pretty=format:'%C(auto)%h %C(red)%as %C(blue)%aN%C(auto)%d%C(green) %s'
```
 
 Where,

- `--pretty=format:`: Customizes the log output.
    - `%C(auto)`: Auto-colorizes sections.
    - `%h`: Abbreviated commit hash.
    - `%as`: Author date in short format.
    - `%aN`: Author name.
    - `%d`: Ref names like branches and tags.
    - `%s`: Commit subject/message.
- `--no-pager`: Outputs directly to the terminal, bypassing Git’s pager.
- `-1` or `-20`: Limits the output to the last 1 or 20 commits, respectively.
## Anonymous Commits with _git acommit_

Haha this was just a fun one to define. The email and name in the `gitconfig` doesn't mean much. It's actually possible to temporarily make yourself "anonymous". The `git acommit` alias lets me do just that, replacing my user details with "Anonymous."

Here's an example:

```console
foo@bar:~/my-awesome-repo$ git acommit -m "Fix typo"
[main 8b5a2f3] Fix typo
 Author: Anonymous <notme@localhost>
```

Here's how it's possible to set it up

```bash
[alias]
    acommit = -c user.name="Anonymous" -c user.email="notme@localhost" commit
```

Where:

- `-c user.name`: Temporarily sets the commit author name.
- `-c user.email`: Temporarily sets the commit author email.
- `commit`: Performs the actual commit.
## Undo with _git uncommit_

Do you know what the [second most popular](https://stackoverflow.com/questions?tab=Votes) question is on Stack Overflow? It's [How do I undo the most recent local commits in Git?](https://stackoverflow.com/questions/927358/how-do-i-undo-the-most-recent-local-commits-in-git). There's a pretty good reason why this question has over 15 million views! We run into this problem quite frequently! I honor of this, I created `git uncommit`:

```console
foo@bar:~/my-awesome-repo$ git uncommit
Unstaged changes after reset:
M       src/app.js
```

Which is basically just an alias of the [top comment](https://stackoverflow.com/a/927386)

```bash
[alias]
    uncommit = reset HEAD~1 --soft
```

where,
- `reset HEAD~1`: Moves the HEAD pointer back one commit.
- `--soft`: Keeps changes staged but removes the last commit.
## Branch Management with _git nb_ and _git nbm_

Creating and publishing branches often requires several commands. These aliases streamline the process. With `git nb`, I can create and push a new branch from the current branch, while `git nbm` does the same from the `main` branch. Here's how that would look like:

```console
foo@bar:~/my-awesome-repo$ git nb feature/add-logging
Switched to a new branch 'feature/add-logging'
Total 0 (delta 0), reused 0 (delta 0)
To github.com:user/repo.git
 * [new branch]      feature/add-logging -> feature/add-logging
```

The alias is simply the steps you would normally follow.

```bash
[alias]
    nb = "!f() { git checkout -b \"$1\" && git push -u origin \"$1\"; }; f"
    nbm = "!f() { git checkout main && git pull && git checkout -b \"$1\" && git push -u origin \"$1\"; }; f"
```

where,

- `git checkout -b "$1"`: Creates a new branch with the given name.
- `git push -u origin "$1"`: Pushes the new branch to the remote and tracks it.
- `git pull`: Updates the `main` branch before creating a new branch in `nbm`.

## Tag Management with _git latest-tag_ and _git tag10_

Tags help mark important points in a repository, like releases. `git latest-tag` fetches the most recent tag, while `git tag10` lists the last 10 tags.

```console
foo@bar:~/my-awesome-repo$ git latest-tag
v1.1.0
```

The alias is defined as

```bash
[alias]
    latest-tag = !git tag --sort=-v:refname | head -n 1
    tag10 = "!git tag -l --sort=-creatordate | head -n 10"
```

Where,

- `tag --sort=-v:refname`: Sorts tags by semantic version in descending order.
- `head -n 1`: Displays the most recent tag.
- `tag -l --sort=-creatordate`: Lists all tags sorted by creation date.
- `head -n 10`: Displays the last 10 tags.

## Conclusion

I hope you enjoyed this mini blog sharing my favorite Git Alias Commands. If you're interested in my entire `gitconfig`, you can copy it from my [gitconfig](https://github.com/Johandielangman/gitconfig) repository.
