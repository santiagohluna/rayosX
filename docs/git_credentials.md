## Gestionar credenciales de Git y GitHub

1. Crear clave con `gpg --gen-key`.
2.  Inicializar clave con `pass init <gpg-id>` donde `<gpg-id>` es la clave generada en el paso anterior. Si no está instaldo, ejecutar `sudo apt install pass.`
3. Ejecutar: `git config --global credential.credentialStore gpg`.
4. Descargar gcm e instalarlo con: `sudo dpkg -i <path-to-package>`.
5. Configurar gcm: `git-credential-manager configure`.

[Volver al menú principal](../README.md).