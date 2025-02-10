#!/usr/bin/bash

# Script para la descarga de observaciones "crudas".

clear

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data/obs"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

# Comparar rutas
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo "Se cambió el directorio de trabajo a $(pwd)"
fi

op=0

while [[ $op -ne 3 ]]; do
    echo -e "\n================================"
    echo "Descarga de observaciones crudas"
    echo -e "================================\n"
    echo "1. Descargar observación de NuSTAR"
    echo "2. Descargar observación de XMM-Newton"
    echo -e "3. Salir\n"
    read -p "Ingrese 1, 2 o 3 para seleccionar la opción deseada: " -e op
    echo
    
    if [[ $op -eq 1 ]] || [[ $op -eq 2 ]]; then
        read -p "Ingrese el ID de la observación: " -e obsid
        echo " "
        if [[ $op -eq 1 ]]; then
            if [ ! -d nustar ]; then
                mkdir nustar
            fi
            cd nustar
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/auxil/
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/hk/
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/event_uf/
            echo -e "\nDescomprimiendo los archivos."
            gzip -d ${obsid}/auxil/*.gz
            gzip -d ${obsid}/hk/*.gz
            gzip -d ${obsid}/event_uf/*.gz
            echo -e "\n¡Listo!"
            cd ..
        elif [[ $op -eq 2 ]]; then
            if [ ! -d xmm ]; then
                mkdir xmm
            fi
            cd xmm
            wget -nH --no-check-certificate --cut-dirs=4 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/xmm/data/rev0//${obsid}/ODF/
            cd ${obsid}/ODF
            echo -e "\nDescomprimiendo los ODF"
            gzip -d *.gz
            echo -e "\n¡Listo!"
            cd ../../../
        fi
        echo -e "\nDescarga completa."
    elif [[ $op -eq 3 ]]; then
        break
    else
        echo "Debe ingresar 1, 2 o 3."
    fi
done
