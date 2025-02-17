#!/usr/bin/bash

# Script para la descarga de observaciones "crudas".

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

clear

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

# Verificar que la ubicación sea la correcta.
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo "Se cambió el directorio de trabajo a $(pwd)"
fi

# Se definen algunos arreglos

nudirs=(
        "auxil"
        "hk"
        "event_uf"
    )

# Se inicializa la variable en la que se guarda la selección del usuario.
op=0

while [[ $op -ne 3 ]]; do
    # Imprimir menú principal.
    echo -e "\n================================"
    echo -e "Descarga de observaciones crudas"
    echo -e "================================\n"
    echo "1. Descargar observación de NuSTAR"
    echo "2. Descargar observación de XMM-Newton"
    echo -e "3. Salir\n"
    # Pedir al usuario que ingrese la opción elegida.
    read -p "Ingrese 1, 2 o 3 para seleccionar la opción deseada: " -e op
    echo
    
    case $op in
        "1" | "2" )
            # Pedir al usuario que ingrese el ID de la observación correspondiente.
            read -p "Ingrese el ID de la observación: " -e obsid
            echo
            opt=$op
            case $opt in
                "1" ) # Ejecutar en caso de que el usuario elija descargar una observación de NuSTAR.
                    if [ ! -d nustar ]; then
                        # Crear carpeta 'nustar' en caso de que no exista.
                        echo -e "\nCreando carpeta 'nustar'."
                        mkdir nustar
                        echo -e "\n¡Listo!"
                    fi
                    # Cambiar al directorio 'nustar' en donde se van a descargar las observaciones.
                    cd nustar
                    
                    if [ ! -d "$obsid" ]; then
                        # Crear carpeta nombrada con el ObsID correspondiente en caso de que no exista.
                        echo -e "\nCreando carpeta '${obsid}'."
                        mkdir "${obsid}"
                        echo -e "\n¡Listo!"
                    fi
                    # Cambiar a la carpeta nombrada con el ObsId correspondinte
                    cd ${obsid}
                    echo -e "\nSe cambió al directorio $(pwd)."
                    # Crear el archivo log
                    LOG_FILE="obsdl_obsID_"$obsid"_"$(date +'d%Y%m%d_t%H%M%S')".log"
                    # Imprimir el encabezado en el log.
                    echo "================" >> "$LOG_FILE"
                    echo "obsdl - Log file" >> "$LOG_FILE"
                    echo "================" >> "$LOG_FILE"
                    # Escribir lista de comandos ejecutados en el log.
                    printf "\nComandos ejecutados" >> "$LOG_FILE"
                    printf "\n===================\n" >> "$LOG_FILE"
                    # Descaragar las carpetas necesarias con las observaciones y archivos auxiliares.
                    for dir in "${nudirs[@]}"; do
                        CMD="wget -nH --no-check-certificate --cut-dirs=8 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/$dir/"
                        echo -e "\nEjecutando '$CMD'"| tee -a "$LOG_FILE"
                        eval $CMD
                        echo
                    done
                    # Descomprimir los archivos descargados.
                    echo -e "\nDescomprimiendo los archivos."
                    for dir in "${nudirs[@]}"; do
                        CMD="gzip -d $dir/*.gz"
                        echo -e "\nEjecutando '$CMD'"| tee -a "$LOG_FILE"
                        eval $CMD
                        echo
                    done
                    if [ ! -d clean ]; then
                        echo -e "\nCreando carpeta 'clean'."
                        mkdir clean
                        echo -e "\n¡Listo!"
                    fi
                    if [ ! -d prods ]; then
                        echo -e "\nCreando carpeta 'prods'."
                        mkdir prods
                        echo -e "\n¡Listo!"
                    fi
                    echo -e "\nDescarga finalizada."
                    cd $RUTA_ACTUAL
                    ;;
                "2" ) # Ejecutar en caso de que el usuario elija descargar una observación de XMM-Newton.
                    if [ ! -d xmm ]; then
                        # Crear la carpeta 'xmm' si no existe. 
                        mkdir xmm
                    fi
                    cd xmm
                    if [ ! -d "$obsid" ]; then
                        # Crear carpeta nombrada con el ObsID correspondiente en caso de que no exista.
                        echo -e "\nCreando carpeta '${obsid}'."
                        mkdir "${obsid}"
                        echo -e "\n¡Listo!"
                    fi
                    # Cambiar a la carpeta nombrada con el ObsId correspondinte
                    cd ${obsid}
                    echo -e "\nSe cambió al directorio $(pwd)."
                    # Crear el archivo log
                    LOG_FILE="obsdl_obsID_"$obsid"_"$(date +'d%Y%m%d_t%H%M%S')".log"
                    # Imprimir el encabezado en el log.
                    echo "================" >> "$LOG_FILE"
                    echo "obsdl - Log file" >> "$LOG_FILE"
                    echo "================" >> "$LOG_FILE"
                    # Escribir lista de comandos ejecutados en el log.
                    printf "\nComandos ejecutados" >> "$LOG_FILE"
                    printf "\n===================\n" >> "$LOG_FILE"
                    # Descargar los archivos ODF.
                    eval "wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/xmm/data/rev0//${obsid}/ODF/"
                    # Descomprimir los archivos descargados.
                    echo -e "\nDescomprimiendo los ODF"
                    gzip -d ${obsid}/ODF/*.gz
                    echo -e "\n¡Listo!"
                    # Preparar las observaciones para reducir y luego analizar.
                    cd ODF
                    echo -e "\nSe cambió al directorio $(pwd)."
                    # Definir la variable de entorno SAS_ODF.
                    export SAS_ODF=.
                    # Iniciar HEASoft
                    echo -e "\nIniciando HEASoft." | tee -a "$LOG_FILE"
                    eval "heainit"
                    # Iniciar SAS
                    echo -e "\nIniciando SAS." | tee -a "$LOG_FILE"
                    eval "sasinit" >> "$LOG_FILE" 2>&1
                    ## Ejecutar la tarea cifbuild, la cual crea el archivo `cif.ccf`.
                    echo -e "\nEjecutando: cifbuild" | tee -a "$LOG_FILE"
                    eval "cifbuild" >> "$LOG_FILE" 2>&1
                    # Apuntar la variable de entorno SAS_CCF al archivo cif.ccf generado por la tarea cifbuild
                    export SAS_CCF="cif.ccf"
                    echo -e "\nArchivo SAS_CCF configurado: $SAS_CCF" | tee -a "$LOG_FILE"
                    echo -e "\n----------------------" >> "$LOG_FILE"
                    ## Ejecutar tarea odfingest
                    echo -e "\nEjecutando: odfingest" | tee -a "$LOG_FILE"
                    eval "odfingest" >> "$LOG_FILE" 2>&1
                    # Volver a la carpeta nombrada con el ObsID correspondiente.
                    cd ..
                    if [ ! -d clean ]; then
                        echo -e "\nCreando carpeta 'clean'."
                        mkdir clean
                        echo -e "\n¡Listo!"
                    fi
                    if [ ! -d prods ]; then
                        echo -e "\nCreando carpeta 'prods'."
                        mkdir prods
                        echo -e "\n¡Listo!"
                    fi
                    echo -e "\nDescarga finalizada."
                    cd $RUTA_ACTUAL
                    ;;
                esac
                ;;
        "3" )
            break
            ;;
        * )
            echo -e "\nDebe ingresar 1, 2 o 3."
            ;;
    esac
done
