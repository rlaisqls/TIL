
> <https://stackoverflow.com/questions/7241678/how-to-prevent-many-git-conflicts-when-rebasing-many-commits>

## rebase via merge

Let me share one possible way to resolve rebase conflicts. I call it rebase via merge. It can help if you want to rebase a branch with many commits and many conflicts are expected.

First, let's create a temp branch and force all conflicts to show up with a regular merge

```
git checkout -b temp
git merge origin/master
```

Resolve all the conflicts the regular way and finish the merge.

So temp branch now shows how the project should look like with all the conflicts resolved correctly.

Now let's checkout your untouched branch back (let it be alpha).

```
git checkout alpha
```

And do a rebase with mechanical conflict auto-resolution in favor of current branch.

```
git rebase origin/master -X theirs
```

The project code can be broken or invalid at this moment. That's fine, the last step is to restore the project state from temp branch with a single additional commit

```
git merge --ff $(git commit-tree temp^{tree} -m "Fix after rebase" -p HEAD)
```

Basically, this step uses a low-level git command to create a new commit with exact same project state (tree) as in temp branch. And that new commit is being merged immediately.

That's it. We just did a rebase via hidden merge. And temp branch can be deleted.

```
git branch -D temp
```

Also, there is a script to do the same thing interactively. It can be found [here](https://github.com/capslocky/git-rebase-via-merge)
