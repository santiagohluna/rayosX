#!/usr/bin/bash

# Script para la descarga de observaciones "crudas".

clear

op=0

while [[ $op -ne 3 ]]; do
    echo -e "\n================================"
    echo "Descarga de observaciones crudas"
    echo -e "================================\n"
    echo -e "Seleccione una de las opciones que se muestra a continuación:\n"
    echo " "
    echo "1. Descargar observación de NuSTAR"
    echo "2. Descargar observadción de XMM-Newton"
    echo -e "3. Salir\n"
    read op
    
    if [[ $op -eq 1 ]] || [[ $op -eq 2 ]]; then
        echo "Ingrese el ID de la observación:"
        echo " "
        read obsid
        echo " "
        if [[ $op -eq 1 ]]; then
            if [ ! -d nustar ]; then
                mkdir nustar
            fi
            cd nustar
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/auxil/
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/hk/
            wget -nH --no-check-certificate --cut-dirs=6 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/nustar/data/obs/${obsid:1:2}/${obsid:0:1}//${obsid}/event_uf/
            cd ..
        elif [[ $op -eq 2 ]]; then
            if [ ! -d xmm ]; then
                mkdir xmm
            fi
            cd xmm
            wget -nH --no-check-certificate --cut-dirs=4 -r -w1 -l0 -c -N -np -R 'index*' -erobots=off https://heasarc.gsfc.nasa.gov/FTP/xmm/data/rev0//${obsid}/ODF/
            cd ..
        fi
        echo " "
        echo "Descarga completa."
        echo " "
    elif [[ $op -eq 3 ]]; then
        break
    else
        echo "Debe ingresar 1, 2 o 3."
    fi
done
