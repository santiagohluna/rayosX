# Obtención de curvas de luz y espectros a partir de las observaciones de NuSTAR

Para este instructivo, se utiliza la observación ID 30201023002 de RT Cru.

1. Ejecutar la metatarea nupipeline:

`nupipeline indir=/path/to/directory/30201023002 steminputs=nu30201023002 outdir =./out saacalc=3 saamode=strict tentacle=yes clobber=yes`
En este caso particular, se han especificado instrucciones especiales para el cálculo del paso por la anomalía del Atlántico Sur.

Se crea la carpeta `out` con la lista de eventos filtrada y otros archivos importantes.

2. Abrir las listas de eventos filtrada, para cada módulo (A y B), con `ds9`: 

`ds9 nu30201023002A01_cl.evt`

3. Seleccionar las regiones correspondientes a la fuente y el background. Utilizar el sistema de coordenadas del detector.
4. Editar los archivos donde se guardó la información de las regiones de manera que estos contengan solamente la especificación de la forma de la región y los parámetros correspondientes. Por ejemplo:
 `circle(525.30556,465.69907,31.275603)` para el caso de la fuente observada en el módulo A.
5. Ejecutar la metatarea `nuproducts` para obtener la curva de luz y el espectro de la fuente y del background:
`nuproducts srcregionfile=./out/srcB.reg bkgregionfile=./out/bgB.reg indir=./out outdir=./products instrument=FPMB steminputs=nu30201023002 stemout=src_bck_B bkgextract=yes clobber=yes`

La opción `clobber=yes` hace que estas metatareas sobreescriban los archivos que se generan al ejecutarlas cada vez que se vuelvan a correr con los mismos parámetros de entrada y salida.

[Volver al menú principal](../README.md).
