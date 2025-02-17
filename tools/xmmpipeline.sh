#!/bin/bash

clear

echo -e '\n============'
echo -e 'XMM Pipeline'
echo -e '============'
echo -e '\nScript para el reprocesamiento y filtrado de la lista de eventos de observaciones de XMM-Newton'

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

echo -e "\nVerificando si el directorio de trabajo es $RUTA_ESPERADA"

# Comparar rutas
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo -e "\nSe cambió el directorio de trabajo a $(pwd)"
fi

if [ ! -d xmm ]; then
    mkdir xmm
fi
cd xmm

## Reprocesamiento de las observaciones

# Verificar si hay observaciones para procesar.
obs_path="$RXPATH/data/obs/xmm"
readarray obs < <(ls $obs_path)
if [ "${#obs[@]}" -eq 0 ]; then
    printf "¡Advertencia!: No existen observaciones a procesar. Debe descargarlas primero."
    exit 1
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

# Almacenar la ruta hacia los archivos con las observaciones a procesar.
indir=/home/shluna/Proyectos/rayosX/data/obs/xmm/$obsid/ODF

# Apuntar la variable `SAS_ODF` a la carpeta donde se encuentran las observaciones
export SAS_ODF=${indir}

echo "Variable SAS_ODF: ${SAS_ODF}."

# Cadena para el nombre de la carpeta de salida y log.
STAMP="obsID_"$obsid"_"$(date +'d%Y%m%d_t%H%M%S')

# Crear la carpeta donde se van a almacenar los archivos que resultan de la reducción.
outdir=$STAMP

if [ ! -d $outdir ]; then
    mkdir $(echo $outdir)
fi

cd ${outdir}

echo -e "\nCarpeta actual: $(pwd)"

# Crear el archivo log
LOG_FILE=$STAMP"_xmmpipeline_log.txt"

# Lista de comandos a ejecutar
COMMANDS=(
    # Iniciar HEASoft
    "heainit"
    # Iniciar SAS
    "sasinit"
    #
    # Reprocesamiento de las observaciones
    #
    ## Ejecutar tarea emproc
    "emproc"
    #
    ## Ejecutar tarea epproc
    "epproc"
    #
    # Filtrado de la lista de eventos.
    #
    "shopt -s nullglob; for file in *_*_EPN_*_ImagingEvts.ds; do if [ -f \"\$file\" ]; then cp \"\$file\" PN.fits >> \"\$LOG_FILE\"; fi; done"
    "shopt -s nullglob; for file in *_*_EMOS1_*_ImagingEvts.ds; do if [ -f \"\$file\" ]; then cp \"\$file\" M1.fits >> \"\$LOG_FILE\"; fi; done"
    "shopt -s nullglob; for file in *_*_EMOS2_*_ImagingEvts.ds; do if [ -f \"\$file\" ]; then cp \"\$file\" M2.fits >> \"\$LOG_FILE\"; fi; done"
    ## Extraer una curva de luz de eventos singulares (con patrón “0”) a energías por encima de 10 keV para cada cámara (PN, MOS1, MOS2) para identificar los intervalos de alto background, usando la tarea `evselect` de SAS:
    "evselect table=PN.fits withrateset=Y rateset=ratesPN.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)'"
    "evselect table=M1.fits withrateset=Y rateset=ratesM1.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'"
    "evselect table=M2.fits withrateset=Y rateset=ratesM2.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'"
    #
    ## Usando la tarea `tabgtigen` se determinan los intervalos de tiempo en los que la curva de luz es baja y constante eligiendo un límite o *threshold* (en cuentas por segundo) para crear el archivo GTI, `EPICgti.fits`: 
    "tabgtigen table=ratesPN.fits expression='RATE<=0.4' gtiset=PNgti.fits"
    "tabgtigen table=ratesM1.fits expression='RATE<=0.35' gtiset=M1gti.fits"
    "tabgtigen table=ratesM2.fits expression='RATE<=0.35' gtiset=M2gti.fits"
    #
    ##Por último, usamos nuevamente `evselect` para generar la lista de eventos filtrada, `EPICclean.fits`:
    "evselect table=PN.fits withfilteredset=Y filteredset=PNclean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(PNgti.fits,TIME) && (PI>150)'"
    "evselect table=M1.fits withfilteredset=Y filteredset=M1clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M1gti.fits,TIME) && (PI>150)'"
    "evselect table=M2.fits withfilteredset=Y filteredset=M2clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M2gti.fits,TIME) && (PI>150)'"
)

echo "=======================" >> "$LOG_FILE"
echo "XMM Pipeline - Log file" >> "$LOG_FILE"
echo "=======================" >> "$LOG_FILE"

printf "\nComandos ejecutados" >> "$LOG_FILE"
printf "\n===================\n" >> "$LOG_FILE"

for CMD in "${COMMANDS[@]}"; do
    echo "- $CMD" >> "$LOG_FILE"
done

# Ejecutar cada comando y registrar la salida

echo -e "\n================================" >> "$LOG_FILE"
echo -e "Log de ejecución de los comandos" >> "$LOG_FILE"
echo -e "==================================\n" >> "$LOG_FILE"

# Ejecutar heainit y sasinit primero
# Iniciar HEASoft
echo -e "\nEjecutando: heainit" | tee -a "$LOG_FILE"
eval "heainit" >> "$LOG_FILE" 2>&1
echo -e "\nEjecutando: sasinit" | tee -a "$LOG_FILE"
eval "sasinit" >> "$LOG_FILE" 2>&1
echo -e "\n----------------------" >> "$LOG_FILE"

# Reprocesamiento de las observaciones
#
## Ejecutar la tarea cifbuild, la cual crea el archivo `cif.ccf`.
echo -e "\nEjecutando: cifbuild" | tee -a "$LOG_FILE"
eval "cifbuild" >> "$LOG_FILE" 2>&1
# Apuntar la variable SAS_CCF al archivo cif.ccf generado por la tarea cifbuild
export SAS_CCF="cif.ccf"
echo -e "\nArchivo SAS_CCF configurado: $SAS_CCF" | tee -a "$LOG_FILE"
echo -e "\n----------------------" >> "$LOG_FILE"

## Ejecutar tarea odfingest
echo -e "\nEjecutando: odfingest" | tee -a "$LOG_FILE"
eval "odfingest" >> "$LOG_FILE" 2>&1

# Buscar el archivo SUM.SAS
SAS_ODF=$(find . -maxdepth 1 -type f -name "*SUM.SAS" | head -n 1)

# Verificar si se encontró el archivo
if [ -z "$SAS_ODF" ]; then
    echo -e "\nNo se encontró el archivo de resumen." | tee -a "$LOG_FILE"
fi

# Exportar la variable SAS_ODF
echo -e "\nArchivo de resumen encontrado: $SAS_ODF" | tee -a "$LOG_FILE"

# Apuntar la variable SAS_ODF al archivo de resumen generado por odfingest.
export SAS_ODF="${outdir}/$SAS_ODF"
echo -e "\nArchivo SAS_ODF configurado: $SAS_ODF" | tee -a "$LOG_FILE"
echo -e"\n----------------------" >> "$LOG_FILE"

# Encontrar el índice del comando "emproc"
start_index=$(echo "${COMMANDS[@]}" | tr ' ' '\n' | grep -n -m 1 "emproc" | cut -d ':' -f 1)

# Verificar si el comando "emproc" fue encontrado
if [ -z "$start_index" ]; then
    echo -e "\nNo se encontró el comando 'emproc' en la lista." | tee -a "$LOG_FILE"
fi

# Ejecutar los comandos desde "epproc" en adelante
for ((i=$start_index; i<${#COMMANDS[@]}; i++)); do
    CMD="${COMMANDS[$i]}"
    echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
    eval "$CMD" >> "$LOG_FILE" 2>&1
    echo -e "\n----------------------" >> "$LOG_FILE"
done

echo -e "\n¡Listo!" >> "$LOG_FILE"

echo -e "\nEjecución completada. Ver $LOG_FILE para detalles.\n"

echo -e "\nAbrir los archivos PNclean.fits, M1clean.fits y M2clean.fits con ds9 y seleccionar las regiones correspondientes a la fuente y al background para continuar con la generación de productos (espectro y curvas de luz). Guardar las regiones usando las coordenadas físicas.\n" | tee -a  "$LOG_FILE"

cd $RUTA_ESPERADA
