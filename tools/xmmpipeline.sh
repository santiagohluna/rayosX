#!/bin/bash

clear

echo -e '\n============'
echo -e 'XMM Pipeline'
echo -e '============'
echo -e '\nScript para el filtrado de la lista de eventos de observaciones de XMM-Newton'

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

# Ruta al directorio tools
TOOLSPATH="/home/shluna/Proyectos/rayosX/tools"

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

obsidir=$RUTA_ESPERADA/$obsid

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

# Ruta al archivo con los comandos
FILE_PATH="$TOOLSPATH/xmmpipeline.cmnds"

# Inicializar un array vacío
COMMANDS=()

# Leer el archivo línea por línea
while IFS= read -r line; do
    # Quitar espacios en blanco al inicio y fin
    line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Ignorar líneas vacías o que comienzan con "#" (comentarios)
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi

    # Agregar el comando al array
    COMMANDS+=("$line")
done < "$FILE_PATH"

# Cadena para el nombre del log.
STAMP=$(date +'d%Y%m%d_t%H%M%S')

# Carpeta donde se van a guardar los productos del pipeline.
outdir="PLO_"$STAMP
mkdir -p $obsidir/$outdir
cd $obsidir/$outdir
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

# Crear el archivo log
LOG_FILE="xmmpipeline_"$STAMP".log"

# Escribir el header del log.
echo "=======================" >> "$LOG_FILE"
echo "XMM Pipeline - Log file" >> "$LOG_FILE"
echo "=======================" >> "$LOG_FILE"

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

echo -e "\nComandos a ejecutar"
echo -e "===================\n"

for CMD in "${COMMANDS[@]}"; do
    echo "- $CMD"
done

# Dar la opción al usuario de confirmar los comandos a ejecutar.
while true; do
    printf "\n¿Confirma ejecutar estos comandos? [(s)í/(n)o] "
    read op
    case $op in
        [Ss]* )
            echo -e "\nComandos ejecutados" >> "$LOG_FILE"
            echo -e "===================\n" >> "$LOG_FILE"

            for CMD in "${COMMANDS[@]}"; do
                echo "- $CMD" >> "$LOG_FILE"
            done
            # Ejecutar cada comando y registrar la salida

            echo -e "\n================================" >> "$LOG_FILE"
            echo -e "Log de ejecución de los comandos" >> "$LOG_FILE"
            echo -e "================================" >> "$LOG_FILE"

            # Ejecutar los comandos definidos en el arreglo "INIT".
            for CMD in "${INIT[@]}"; do
                echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
                echo >> "$LOG_FILE" 2>&1
                eval "$CMD" >> "$LOG_FILE" 2>&1
                echo -e "\n----------------------" >> "$LOG_FILE"
            done

            # Ejecutar los comandos definidos en el arreglo "COMMANDS".
            for CMD in "${COMMANDS[@]}"; do
                echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
                echo >> "$LOG_FILE" 2>&1
                eval "$CMD" >> "$LOG_FILE" 2>&1
                echo -e "\n----------------------" >> "$LOG_FILE"
            done

            echo -e "\n¡Listo!" >> "$LOG_FILE"

            echo -e "\nLimpiando."
            rm *.fits

            echo -e "\nEjecución finalizada [$(date +'%d/%m/%Y - %H:%M:%S')]." | tee -a "$LOG_FILE"
            echo -e "\n Ver $LOG_FILE para detalles.\n"

            echo -e "\nAbrir los archivos PNclean.fits, M1clean.fits y M2clean.fits con ds9 y seleccionar las regiones correspondientes a la fuente y al background para continuar con la generación de productos (espectro y curvas de luz). Guardar las regiones usando las coordenadas físicas.\n" | tee -a  "$LOG_FILE"
            break
        ;;
        [Nn]* ) 
            echo -e "\nEdite los comandos a ejecutar en el archivo xmmpipeline.cmnd, que se encuentra dentro de la carpeta '$TOOLSPATH', y vuelva a ejecutar xmmpipeline."
            exit 0
        ;;
        * ) echo -e "\nDebe ingresar 's' o 'n'.";;
    esac
done

cd $RUTA_ESPERADA
