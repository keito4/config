## installation

### Unix

```
cat ./extensions.txt | xargs -L 1 code --install-extension
```

### Windows

```
cat ./extensions.txt | % { "code --install-extension \$\_" }
```
