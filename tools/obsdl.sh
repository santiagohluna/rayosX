#!/usr/bin/bash

# Script para la descarga de observaciones "crudas".

#set -e  # Detener la ejecución si ocurre un error

clear

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

# Verificar que la ubicación sea la correcta.
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd "$RUTA_ESPERADA"
    echo "Se cambió el directorio de trabajo a $(pwd)"
fi

# Se definen algunos arreglos
nudirs=("auxil" "hk" "event_uf")

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
    read -p "Ingrese 1, 2 o 3 para seleccionar la opción deseada: " -e op
    echo
    
    case $op in
        "1" | "2" )
            read -p "Ingrese el ID de la observación: " -e obsid
            echo
            opt=$op
            case $opt in
                "1" ) # NuSTAR
                    # Crear las carpetas con el ObsID, 'clean' y prods si no existen.
                    mkdir -p nustar/"$obid"
                    cd nustar/"$obsid"
                    echo -e "\nSe cambió al directorio $(pwd)."
                    mkdir -p clean prods
                    LOG_FILE="obsdl_obsID_${obsid}_$(date +'d%Y%m%d_t%H%M%S').log"
                    echo "================" >> "$LOG_FILE"
                    echo "obsdl - Log file" >> "$LOG_FILE"
                    echo "================" >> "$LOG_FILE"
                    printf "\nComandos ejecutados\n===================\n" >> "$LOG_FILE"
                    for dir in "${nudirs[@]}"; do
                        CMD="wget -nH --no-check-certificate --cut-dirs=8 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off \"https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs//${obsid:1:2}/${obsid:0:1}/${obsid}/$dir/\""
                        echo -e "\nEjecutando '$CMD'" | tee -a "$LOG_FILE"
                        eval $CMD || { echo "Error en descarga"; exit 1; }
                    done
                    echo -e "\nDescomprimiendo archivos."
                    for dir in "${nudirs[@]}"; do
                        if ls "$dir"/*.gz &>/dev/null; then
                            gzip -d "$dir"/*.gz
                        fi
                    done
                    echo -e "\nDescarga finalizada."
                    cd "$RUTA_ACTUAL"
                    ;;
                "2" ) # XMM-Newton
                    # Crear las carpetas con el ObsID, 'clean' y prods si no existen.
                    mkdir -p xmm/"$obsid"
                    cd xmm/"$obsid"
                    echo -e "\nSe cambió al directorio $(pwd)."
                    mkdir -p clean prods
                    LOG_FILE="obsdl_obsID_${obsid}_$(date +'d%Y%m%d_t%H%M%S').log"
                    echo "================" >> "$LOG_FILE"
                    echo "obsdl - Log file" >> "$LOG_FILE"
                    echo "================" >> "$LOG_FILE"
                    printf "\nComandos ejecutados\n===================\n" >> "$LOG_FILE"
                    eval "wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off \"https://heasarc.gsfc.nasa.gov/FTP/xmm/data/rev0//${obsid}/ODF/\""
                    echo -e "\nDescomprimiendo los ODF"
                    if ls ODF/*.gz &>/dev/null; then
                        gzip -d ODF/*.gz
                    fi
                    # Preparar las observaciones para reducir y luego analizar.
                    cd ODF
                    export SAS_ODF="."
                    echo -e "\nSe cambió al directorio $(pwd)."
                    echo -e "\nIniciando HEASoft." | tee -a "../$LOG_FILE"
                    eval "heainit"
                    echo -e "\nIniciando SAS." | tee -a "../$LOG_FILE"
                    eval "sasinit" >> "../$LOG_FILE" 2>&1
                    echo -e "\nEjecutando: cifbuild" | tee -a "../$LOG_FILE"
                    eval "cifbuild" >> "../$LOG_FILE" 2>&1
                    export SAS_CCF="ccf.cif"
                    echo -e "\nArchivo SAS_CCF configurado: $SAS_CCF" | tee -a "../$LOG_FILE"
                    echo -e "\nEjecutando: odfingest" | tee -a "../$LOG_FILE"
                    eval "odfingest" >> "../$LOG_FILE" 2>&1
                    cd ..
                    echo -e "\nDescarga finalizada."
                    cd "$RUTA_ACTUAL"
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

