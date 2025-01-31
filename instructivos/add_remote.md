# Agregar repositorio remoto

1. Crear un repositorio nuevo en GitHub, sin agregar archivo alguno (ni README, .gitignore, etc.).
2. Crear una carpeta que va aservir de repositorio local. Luego ejecutar:
    1. `echo "# nombre_del_repo" >> [README.md](http://readme.md/)`
    2. `git init`
    3. `git add [README.md](http://readme.md/)`
    4. `git commit -m "first commit"`
    5. `git branch -M main`
    6. `git remote add origin https://github.com/santiagohluna/analisisRX.git`
    7. `git push -u origin main`
3. Si el repositorio ya existe y está inicializado (es un repo de git), se deben seguir las siguientes instrucciones:
    1. `git remote add origin https://github.com/santiagohluna/analisisRX.git`
    2. `git branch -M main`
    3. `git push -u origin main`

[Volver al menú principal](instructivos.md).