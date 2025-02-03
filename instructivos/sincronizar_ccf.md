# Sincronizar los CCF

Para mantener actualizados los archivos de calibración de XMM-Newton, hay que ir a la carpeta donde están descargados los CCF y ejecutar:

`rsync -v -a --progress --delete --delete-after --force --include='*.CCF' --exclude='*/' sasdev-xmm.esac.esa.int::XMM_VALID_CCF .`

[Volver al menú principal](../README.md).