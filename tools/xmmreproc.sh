#!/usr/bin/bash

# Script para el reprocesamiento de las observaciones de XMM-Newton.

clear

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

# Imprimir menú principal.
echo -e "\n=========="
echo -e "XMM Reproc"
echo -e "=========="
echo -e "\nScript para el reprocesamiento de observaciones de XMM-Newton"

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data/xmm"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

echo -e "\nVerificando si el directorio de trabajo es $RUTA_ESPERADA"

# Comparar rutas
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo -e "\nSe cambió el directorio de trabajo a $(pwd)"
fi

# Verificar si hay observaciones para procesar.
readarray obs < <(ls)
if [ "${#obs[@]}" -eq 0 ]; then
    printf "¡Advertencia!: No existen observaciones a procesar. Debe descargarlas primero."
fi

if [ "$#" -eq 0 ]
then
    printf "\nLista de observaciones posibles a procesar:\n\n"
    for i in ${!obs[@]}
    do 
        printf "$((i+1)). ObsID: %s" "${obs[$i]}"
        i=$((i+1))
    done
    printf "\nIngrese el índice identificador de la observación: "
    read -e id
    obsid=$(printf %s "${obs[$((id-1))]}")
else
    obsid=$1
fi

cd "$obsid"
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

# Listas de comandos a ejecutar

INIT=(
    # Iniciar HEASoft
    "heainit"
    # Iniciar SAS
    "sasinit"
)

REPROC=(
    "epproc"
    "emproc"
)

if [ -d "reproc" ]; then
    # Si existe, eliminarlo
    rm -rf "reproc"
fi
# Crear el directorio de nuevo
mkdir "reproc"
cd reproc
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

# Cadena para el nombre del log.
STAMP=$(date +'d%Y%m%d_t%H%M%S')

# Crear el archivo log
LOG_FILE="xmmreproc_"$STAMP".log"

# Escribir el header del log.
echo "=====================" >> "$LOG_FILE"
echo "XMM Reproc - Log file" >> "$LOG_FILE"
echo "=====================" >> "$LOG_FILE"

# Almacenar la ruta hacia los archivos con las observaciones a procesar.
indir=/home/shluna/Proyectos/rayosX/data/xmm/$obsid/ODF

# Apuntar la variable de entorne SAS_CCF al archivo 'ccf.cif'.
SAS_CCF=$(find $indir -type f -name "ccf.cif")
export SAS_CCF=$SAS_CCF
echo -e "\nVariable de entorno SAS_CCF configurada: $SAS_CCF" | tee -a "$LOG_FILE"
echo -e "\n----------------------" >> "$LOG_FILE"

# Apuntar la variable SAS_ODF al archivo de resumen generado por odfingest.
SAS_ODF=$(find $indir -type f -name "*SUM.SAS")
export SAS_ODF=$SAS_ODF
echo -e "\nVariable de entorno SAS_ODF configurada: $SAS_ODF" | tee -a "$LOG_FILE"
echo -e "\n----------------------" >> "$LOG_FILE"

echo -e "\nComandos ejecutados" >> "$LOG_FILE"
echo -e "===================\n" >> "$LOG_FILE"

for CMD in "${REPROC[@]}"; do
    echo "- $CMD" >> "$LOG_FILE"
done

# Ejecutar cada comando y registrar la salida

echo -e "\n================================" >> "$LOG_FILE"
echo -e "Log de ejecución de los comandos" >> "$LOG_FILE"
echo -e "================================" >> "$LOG_FILE"

# Ejecutar los comandos definidos en el arreglo "INIT".
for CMD in "${INIT[@]}"; do
    echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
    eval "$CMD" >> "$LOG_FILE" 2>&1
    echo -e "\n----------------------" >> "$LOG_FILE"
done

echo -e "\nReprocesando los ODF." | tee -a "$LOG_FILE"
# Ejecutar los comandos definidos en el arreglo "REPROC".
for CMD in "${REPROC[@]}"; do
    echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
    echo >> "$LOG_FILE" 2>&1
    eval "$CMD" >> "$LOG_FILE" 2>&1
    echo -e "\n----------------------" >> "$LOG_FILE"
done

echo -e "\nEjecución finalizada [$(date +'%d/%m/%Y - %H:%M:%S')]." | tee -a "$LOG_FILE"
echo -e "\nVer $LOG_FILE para detalles.\n"
echo -e "\n----------------------" >> "$LOG_FILE"

cd $RUTA_ACTUAL