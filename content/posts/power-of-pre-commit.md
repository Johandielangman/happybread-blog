---
author: Johan Hanekom
title: The Power of Pre-Commit Hooks
date: 2025-04-03
tags:
  - Git
  - Python
draft: "false"
---
![pre-commit-meme.png](/images/pre-commit-meme.png)

I've finally found the tool I've been waiting for! Something that not only solves _my_ lazy habits but also fixes the laziness of entire teams working on the same repository!

🎉 **Pre-Commit** 🎉

As the meme says, "Clean It up!". But what exactly are _bad habits_? What Laziness am I talking about? Let's see if you can spot a few problems.

Take a look at this JSON file someone _quickly_ modified:

```json
{
	"settings": {
		"height": 10.0,
		"width": 20.0
		"depth": 15.0
	}
}
```

What's wrong?

Answer: Someone copy-pasted a new setting but forgot to add a comma after `"width"`. Classic. I've done that.

Now, brace yourself for this Python mess:

```python
def foo(): x=1+2  
 y= 3   
 if x>0:print ("Hello")   
  print ("World") 

def bar():a=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
 b = "some string"    
  c =  42   
print(foo(),bar())   
```

Yikes. 🤢 Did you catch all the issues?
1. Mixed indentation (tabs? spaces? pick a side!)
2. Missing whitespace around operators
3. Expected two blank lines before function definitions
4. A line so long it could wrap around the Earth
5. Trailing whitespace (you didn't even _see_ it, did you?)
6. Local variables assigned but never used

We've all seen (or written) commit messages like:
- `fix`
- `fix`
- `button`
- `new`
- `save`

Descriptive. Helpful. Future-you is _definitely_ going to understand what these mean.

Sure, you _could_ ask everyone nicely to follow best practices. You _could_ tell them to install a bunch of linting tools. But let’s be honest -- relying on good behavior is a losing battle. Even your _own_ good behavior!

I say _nay!_ We live in a world of automation! And guess what? Developers have struggled with these same issues for years.

That’s where the magic of pre-commit hooks comes in. They don’t just warn you -- they **literally** stop you from committing bad code. No joke. Like a brick wall. You _cannot_ commit it.

Why use it?

Because it’s the only way to keep your Git history and entire codebase clean.

Will it be annoying? Oh, absolutely.  
Will it save your future self a world of pain? Without a doubt.

## ⚙ Pre-Commit Setup

This is obviously just my very informal blog. For more in-depth reading, you can have a look at the official documentation over at https://pre-commit.com

### 📥 Installing libraries

Righty righty! Let's start off by making a repository where we can run our tests

```bash
mkdir pre-commit && code pre-commit
```

Now that we have our VS Code open, we can create a virtual environment:

```python
python -m venv .venv && echo ".venv" > .gitignore && source .venv/Scripts/activate
```

Since this blog is about best practice, we're going to stick to it. We're actually going to have two `requirements.txt` files. Yes! TWO! Why? One will be the requirements we'll require when we're doing local dev. This requirements file will have dependencies like `pytest` or the `pre-commit` we're about to install. The other requirements file is the one with all the dependencies when we're deploying the application (to an image or website, for example). We don't require all these tools for our deployment!

So make two files with `touch`:

```bash
touch requirements.txt && touch requirements.local.txt
```

Now! This is where the trick comes in. Add the following in `requirements.local.txt`:

```txt
-r requirements.txt
```

This means that we're actually importing the dependencies from `requirements.txt` into `requirements.local.txt`! So when someone new comes along to start working on out repo, they can simply just run

```bash
pip install -r requirements.local.txt
```

which will install everything from `requirements.txt` and `requirements.local.txt`!

As an example, let's add `requests` to `requirements.txt`:

```txt
requests==2.32.*
```

I recommend to try to version lock any dependency in some way. Just google "pypi requests" and copy the current version from https://pypi.org/project/requests/

And now, for `pre-commit`, we can add the dependency to `requirements.local.txt`:

```txt
-r requirements.txt

pre-commit>=4.2.0
```

Now when we run the pip install for the local requirements, we can see how it install from both files!

```
└❯ pip install -r requirements.local.txt 
Collecting requests==2.32.*
  Using cached requests-2.32.3-py3-none-any.whl (64 kB)
Collecting pre-commit>=4.2.0
```

### 🔍 The first pre-commit hook: Check JSON 

Let's create the file where we'll be storing all of our hooks:

```bash
touch .pre-commit-config.yaml
```

Add the following to the config file:

```yml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    -   id: check-json
```

Here, we're adding the first hook from the pre-commit-hooks repository: `check-json`. But this won't do anything -- yet! We first need a `.git` folder set up!

```bash
git init -b main
```

And now we need to tell our `.git` folder to use our hooks. Run the following:

```bash
pre-commit install --install-hooks
```

The output should look something like this:

```bash
└❯ pre-commit install --install-hooks
pre-commit installed at .git\hooks\pre-commit
[INFO] Initializing environment for https://github.com/pre-commit/pre-commit-hooks.
[INFO] Installing environment for https://github.com/pre-commit/pre-commit-hooks.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
```

The important line is `pre-commit installed at .git\hooks\pre-commit`!

Let's test it! Let's add a JSON file:

```bash
echo '{"bar": "zar"}' > example.json
```

Now stage everything with `git add .`

Now let's run the classic initial commit:

```
└❯ git commit -m "initial commit"
Check JSON...............................................................Passed
[main (root-commit) 31d9d14] initial commit
 5 files changed, 12 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 .pre-commit-config.yaml
 create mode 100644 example.json
 create mode 100644 requirements.local.txt
 create mode 100644 requirements.txt
```

Check JSON passed!

Now let's try to break it! I'm going to make my JSON file the same as the example in the beginning...

```json
{
	"settings": {
		"height": 10.0,
		"width": 20.0
		"depth": 15.0
	}
}
```

Let's add and commit:

```
└❯ git add . && git commit -m "fix: better json file"
The file will have its original line endings in your working directory
Check JSON...............................................................Failed
- hook id: check-json
- exit code: 1

example.json: Failed to json decode (Expecting ',' delimiter: line 5 column 3 (char 53))
```

Ah! Look at that! It failed. Let's fix it and try again

```json
{
	"settings": {
		"height": 10.0,
		"width": 20.0,
		"depth": 15.0
	}
}
```

```text
└❯ git add . && git commit -m "fix: better json file"
The file will have its original line endings in your working directory
Check JSON...............................................................Passed
[main 4bd094e] fix: better json file
 1 file changed, 7 insertions(+), 1 deletion(-)
```

It worked! 🥳

But will this scan every single file JSON file we add? Actually no! It only scans files that are staged!

Let's create a new file:

```bash
echo "todo: ready happybread.net" > todo.txt
```

And if we commit now:

```
└❯ git add . && git commit -m "feat: new todo notes"
The file will have its original line endings in your working directory
Check JSON...........................................(no files to check)Skipped
[main 9bd46e0] feat: new todo notes
 2 files changed, 1 insertion(+), 1 deletion(-)
 create mode 100644 todo.txt
```

Great! So it skipped!

### ❓ Other pre-commit hooks from the pre-commit repository

There are *several* pre-commit hooks you can add. Go to https://github.com/pre-commit/pre-commit-hooks for a full list of a few "quick wins".

I like the following ones:

```yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    -   id: check-yaml
    -   id: check-toml
    -   id: check-json
    -   id: end-of-file-fixer
    -   id: trailing-whitespace
    -   id: no-commit-to-branch
        args: ["--branch", "main", "--pattern", "^(?!feature/|chore/|bug/|hotfix/|release/).*$"]
```

So we're checking to see if we have broken any `json`, `yaml` or `toml` files, we're making sure that we end our files with a newline and a newline only, we're removing trailing whitespaces and preventing users from committing straight to main! On that note, time to get out of main...

But first... while we're here in main, let's see what happens when we *try* to push to main

```
└❯ git add . && git commit -m "fix: test commit to main"
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Failed
- hook id: no-commit-to-branch
- exit code: 1
```

Blocked! 🍌 Now let's go to a bad branch name... 

```bash
git checkout -b temp
```

```
└❯ git add . && git commit -m "fix: test commit to main"
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Failed
- hook id: no-commit-to-branch
- exit code: 1
```

Blocked! 🍌

Let's use a real branch name:

```bash
git checkout -b feature/pre-commit-config
git add . && git commit -m "fix: new configuration"
```

### 🧼 flake8 linting

haha I wanted to start writing about Flake 8 rules. I typed it into Google and I wasn't disappointed!

![i_visit_often](/images/i_visit_often.png)

Anyways! Flake 8 Rules are what makes Python Clean! https://www.flake8rules.com 

As the Website says, "The Big Ol' List of Rules". While the pre-commit section will save you from committing rules that break these rules for best standard looking Python, it's good to catch them before you even make the pre-commit mad. I would recommend the following VS Code Extensions:
- [Flake8](https://marketplace.visualstudio.com/items?itemName=ms-python.flake8) - brings the rules into your editor
- [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) - adds the Flake8 errors into your editor, *i.e.*  puts it IN your face!
Ironically, this is still a best effort. I've seen people just ignore these errors, even if it's in their face!

That's where the pre-commit hooks comes in

```yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    -   id: check-yaml
    -   id: check-toml
    -   id: check-json
    -   id: end-of-file-fixer
    -   id: trailing-whitespace
    -   id: no-commit-to-branch
        args: ["--pattern", "main", "--pattern", "^(?!feature/|chore/|bug/|hotfix/|release/).*$"]
-   repo: https://github.com/PyCQA/flake8
    rev: 7.2.0
    hooks:
    -   id: flake8
        language_version: python3.11
```

I'm going to copy-pasta (🍝) that bad example at the top of the blog into a new `main.py` file and try to commit that!

```
└❯ git add . && git commit -m "feat: new main file"
[INFO] Initializing environment for https://github.com/PyCQA/flake8.
[INFO] Installing environment for https://github.com/PyCQA/flake8.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Failed
- hook id: end-of-file-fixer
- exit code: 1
- files were modified by this hook

Fixing .pre-commit-config.yaml
Fixing main.py

Trim Trailing Whitespace.................................................Failed
- hook id: trailing-whitespace
- exit code: 1
- files were modified by this hook

Fixing main.py

Don't commit to branch...................................................Passed
flake8...................................................................Failed
- hook id: flake8
- exit code: 1

main.py:2:2: E999 IndentationError: unexpected inden
```

So we can see how some of the other pre-commits actually tried to fix as much as possible!

Let's run the add and commit again:

```
└❯ git add . && git commit -m "feat: new main file"
warning: LF will be replaced by CRLF in .pre-commit-config.yaml.
The file will have its original line endings in your working directory
warning: LF will be replaced by CRLF in main.py.
The file will have its original line endings in your working directory
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Passed
flake8...................................................................Failed
- hook id: flake8
- exit code: 1

main.py:2:2: E999 IndentationError: unexpected indent
```

Alright! We're getting blocked by our lint

Here is the fixed version:

```python
def foo():
    x = 1 + 2
    # y = 3
    if x > 0:
        print("Hello")
        print("World")


def bar():
    # a = list(range(1, 31))
    # b = "some string"
    # c =  42
    print(foo(), bar())

```

```
└❯ git add . && git commit -m "feat: new main file"
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Passed
flake8...................................................................Passed
[feature/pre-commit-config 44a37db] feat: new main file
 2 files changed, 18 insertions(+)
 create mode 100644 main.py
```

Great! But I am going to increase the max-line length a bit...

create a `.flake8` file and add the following:

```
[flake8]
max-line-length = 120
ignore = W503, W504
```

Yes I'm ignoring two rules. I don't agree with these two rules at all. Anywhoo. So the line length is now set to be 120 characters, but how do we code with that in mind? Do we count the number of characters on each line? No! Most editors will solve this problem for you.

For VS Code, go to settings, and search for "Editor Rulers". It will prompt you to edit it somewhere else. Modify it to be:

```json
"editor.rulers": [
  120
]
```

It should look something like this:

![editor-ruler](/images/editor-ruler.png)

So now, when we code, we can keep our eyes on this line to make sure that we never go over 120 characters

### 📖 Conventional Commit Messages

Conventional Commits! This is one area I wish to self-improve. The [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification is inspired by, and based heavily on, the [Angular Commit Guidelines](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines).

To quote directly from the specification:

> The Conventional Commits specification is a lightweight convention on top of commit messages. It provides an easy set of rules for creating an explicit commit history; which makes it easier to write automated tools on top of.

The commit message should be structured as follows:

```txt
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

The commit contains the following structural elements, to communicate intent to the consumers of your library:

1. **fix:** a commit of the _type_ `fix` patches a bug in your codebase (this correlates with [`PATCH`](http://semver.org/#summary) in Semantic Versioning).
2. **feat:** a commit of the _type_ `feat` introduces a new feature to the codebase (this correlates with [`MINOR`](http://semver.org/#summary) in Semantic Versioning).
3. **BREAKING CHANGE:** a commit that has a footer `BREAKING CHANGE:`, or appends a `!` after the type/scope, introduces a breaking API change (correlating with [`MAJOR`](http://semver.org/#summary) in Semantic Versioning). A BREAKING CHANGE can be part of commits of any _type_.
4. _types_ other than `fix:` and `feat:` are allowed, for example [@commitlint/config-conventional](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional) (based on the [Angular convention](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines)) recommends `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, and others.

According to the [Angular convention](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines), each type means the following:
- **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- **ci**: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
- **docs**: Documentation only changes
- **feat**: A new feature
- **fix**: A bug fix
- **perf**: A code change that improves performance
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **test**: Adding missing tests or correcting existing tests
- **chore**: commits are for regular maintenance tasks that don't directly modify the source code or affect the application's behavior

Here are the examples from the convention website. Yes, I'm copy-pasta'ing (🍝) , but I know you won't go to the website! So I bring the website to you!


| Type                                                                   | Example                                                                                                                                                                                                                                                                                         |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Commit message with description and breaking change footer             | feat: allow provided config object to extend other configs<br><br>BREAKING CHANGE: `extends` key in config file is now used for extending other config files                                                                                                                                    |
| Commit message with `!` to draw attention to breaking change           | feat!: send an email to the customer when a product is shipped                                                                                                                                                                                                                                  |
| Commit message with scope and `!` to draw attention to breaking change | feat(api)!: send an email to the customer when a product is shipped                                                                                                                                                                                                                             |
| Commit message with both ! and BREAKING CHANGE footer                  | chore!: drop support for Node 6<br><br>BREAKING CHANGE: use JavaScript features not available in Node 6.                                                                                                                                                                                        |
| Commit message with no body                                            | docs: correct spelling of CHANGELOG                                                                                                                                                                                                                                                             |
| Commit message with scope                                              | feat(lang): add Polish language                                                                                                                                                                                                                                                                 |
| Commit message with multi-paragraph body and multiple footers          | fix: prevent racing of requests<br><br>Introduce a request id and a reference to latest request. Dismiss<br>incoming responses other than from latest request.<br><br>Remove timeouts which were used to mitigate the racing issue but are<br>obsolete now.<br><br>Reviewed-by: Z<br>Refs: #123 |

As for the `<description>` of the commit, there is no enforcement, you can say what you want, but here are some good tips:
- use the imperative, present tense: "change" not "changed" nor "changes". Read your commit message as **"This commit will .."** 
- don't capitalize the first letter
- no dot (.) at the end

For the `<body>`, use the imperative, present tense: "change" not "changed" nor "changes". The body should include the motivation for the change and contrast this with previous behavior.

And for the `<footer>`:
- The footer should contain any information about **Breaking Changes** and is also the place to reference GitHub issues that this commit **Closes**.
- Closed bugs should be listed on a separate line in the footer prefixed with "Closes" keyword like this:

```
Closes #234
```

or in case of multiple issues:

```
Closes #123, #245, #992
```

Now! Let's add this pre-commit as well:

```yaml
default_install_hook_types:
    - pre-commit
    - commit-msg

repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    -   id: check-yaml
    -   id: check-toml
    -   id: check-json
    -   id: end-of-file-fixer
    -   id: trailing-whitespace
    -   id: no-commit-to-branch
        args: ["--pattern", "main", "--pattern", "^(?!feature/|chore/|bug/|hotfix/|release/).*$"]
-   repo: https://github.com/PyCQA/flake8
    rev: 7.2.0
    hooks:
    -   id: flake8
        language_version: python3.11
-   repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.0.0
    hooks:
    -   id: conventional-pre-commit
        stages: [commit-msg]
        args: []
```

Since we added a new stage called `commit-msg`, we need to run the following command again:

```bash
pre-commit install --install-hooks
```

It should look like:

```
└❯ pre-commit install --install-hooks
pre-commit installed at .git\hooks\pre-commit
pre-commit installed at .git\hooks\commit-msg
```

Now if we run a non-conventional commit:

```
└❯ git add . && git commit -m "bad commit"
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Passed
flake8...............................................(no files to check)Skipped
Check Yaml...........................................(no files to check)Skipped
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Don't commit to branch...................................................Passed
flake8...............................................(no files to check)Skipped
Conventional Commit......................................................Failed
- hook id: conventional-pre-commit
- exit code: 1

[Bad commit message] >> bad commit
Your commit message does not follow Conventional Commits formatting
https://www.conventionalcommits.org/

Use the --verbose arg for more information

```

It breaks! but `ci(pre-commit): add a new pre-commit hook` will work. 

### 🦹‍♂️ Static Security Scanning using Bandit

Bandit is a tool designed to find common security issues in Python code. To do this Bandit processes each file, builds an AST from it, and runs appropriate plugins against the AST nodes. Once Bandit has finished scanning all the files it generates a report.

It's by no means a perfect solution, but it can help with some common issues.

First, we'll add the report to the `.gitignore`

```bash
 echo ".bandit.report.txt" >> .gitignore
```

Next, we'll add the pre-commit hook:

```yaml
-   repo: https://github.com/pycqa/bandit
    rev: 1.8.3
    hooks:
    -   id: bandit
        args: [ "-ll", "-o", ".bandit.report.txt"]
        files: .py$
```

Where `-ll` specifies to only report on medium issues and `-o` specifies where to write the output file. I prefer the output file since I can always come back to it.

A great way to test it, is to make a GET request to something without a timeout. Let's add the following to our `main.py`:

```python
import requests
response = requests.get("https://google.com")
print(response)
```

and then watch it fail

```
└❯ git add . && git commit -m "feat: add a simple request to the main file"
Check Yaml...............................................................Passed
Check Toml...........................................(no files to check)Skipped
Check JSON...........................................(no files to check)Skipped
Fix End of Files.........................................................Passed
Trim Trailing Whitespace.................................................Passed
Don't commit to branch...................................................Passed
flake8...................................................................Passed
bandit...................................................................Failed
- hook id: bandit
- exit code: 1

[main]  INFO    profile include tests: None
[main]  INFO    profile exclude tests: None
[main]  INFO    cli include tests: None
[main]  INFO    cli exclude tests: None
[main]  INFO    running on Python 3.11.3
[text]  INFO    Text output written to file: .bandit.report.txt
```

Where the report will look something like this:

```text
Run started:2025-04-03 20:08:26.325777

Test results:
>> Issue: [B113:request_without_timeout] Call to requests without timeout
   Severity: Medium   Confidence: Low
   CWE: CWE-400 (https://cwe.mitre.org/data/definitions/400.html)
   More Info: https://bandit.readthedocs.io/en/0.0.0/plugins/b113_request_without_timeout.html
   Location: .\main.py:22:15
21	    b = "b"
22	    response = requests.get("https://google.com")
23	    print(response)

--------------------------------------------------

Code scanned:
	Total lines of code: 18
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0

Run metrics:
	Total issues (by severity):
		Undefined: 0
		Low: 0
		Medium: 1
		High: 0
	Total issues (by confidence):
		Undefined: 0
		Low: 1
		Medium: 0
		High: 0
Files skipped (0):
```

We even get a few links to the reasons: https://cwe.mitre.org/data/definitions/400.html

I especially like the meme:

![b113.png](/images/b113.png)

to address the error:

```python
response = requests.get(
	"https://google.com",
	timeout=30
)
```

## Conclusion

You can have a look at the source code [here](https://github.com/Johandielangman/pre-commit-tests)

Some final remarks:
- I'm still playing around with the configuration and best practice. Always keen to learn how I can improve.
- You don't have to use other people's repositories. You can run custom scripts in these pre-commit hooks
- Yes you can disable them, but you technically shouldn't even know how to do that! Always follow best practice!

Hope you enjoyed this blog!
