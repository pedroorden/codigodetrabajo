### Script de Descarga de Datos COVID-19

# La intensión aquí es poner a disposición de lxs estudiantes 
# interesadxs un código funcional, desmotrativo y abierto, 
# que es la síntesis de una serie de experiencias, estrategias y 
# decisiones metodológicas concretas aplicadas al trabajo con datos
# para el monitoreo del coronavirus.

# Llamamos a las librerias

library(tidyverse)
library(lubridate)
library(data.table)
library(dplyr)
library(fst)
library(ggplot2)

options(scipen=1000)

# Comenzaremos realizando una consulta directa 
# a la base de datos COVID-19 abierta que provee el 
# Estado Nacional a traves del Sistema Integrado de Información 
# Sanitaria Argentino (SISA) https://sisa.msal.gov.ar/

# Establecemos los vectores para la descarga con la ruta de los datos. 

url <- "https://sisa.msal.gov.ar/datos/descargas/covid-19/files/Covid19Casos.zip"
 
temp <- tempfile()


#Descargamos el archivo

download.file(url, temp)


# Lo leemos en R con la poderosa función fread() de data.table, 
# usamos fread en vez de read.csv() porque vamos a 
# descargar un archivo csv pesado.

unzip(temp, "Covid19Casos.csv") #deszippeamos el archivo descargado
 
argentina <- fread("Covid19Casos.csv") #usamos fread de la librería data.table

argentina<-as_tibble(argentina)

head(argentina) 


# Como podremos apreciar el archivo tiene unas dimensiones 
# considerables, a hoy algo mas de 3 gigas, con lo cual procedemos a 
# quedarnos con aquello que nos permita construir un set inicial de 
# variables epidemilógicas, interesará dar con los datos de afectación, 
# edades, fecha ingreso al sistema de salud, residencia, internación y 
# eventual fallecimiento.


ar_positivos <- argentina %>%
   filter(clasificacion_resumen=='Confirmado')%>% #seleccionamos solo a los afectados COVID19
   rename(provincia=residencia_provincia_nombre,
          fecha=fecha_apertura)#la fecha que nos interesa seguir en este caso es las fecha de apertura del caso en el sistema de salud.



ar_positivos$fecha<- ymd(ar_positivos$fecha) #format de fecha


# Importante, normaliza la fecha de menores de un año, 
# de dos columnas hacemos una.


ar_positivos$edad[which(ar_positivos$edad_años_meses=="Meses")]<- 0.5


ar_positivos$edad_años_meses[which(ar_positivos$edad== 0.5 )]<- "Años"


#desechamos las variables que no vamos usar.
ar_positivos <- ar_positivos %>%
   select(!c(clasificacion_resumen, clasificacion, edad_años_meses,
             id_evento_caso, residencia_pais_nombre,
             residencia_departamento_nombre, carga_provincia_nombre,
             fecha_inicio_sintomas, fecha_internacion,
             fecha_cui_intensivo, fecha_fallecimiento, fecha_diagnostico,
             sepi_apertura,carga_provincia_id, residencia_provincia_id,
             residencia_departamento_id, ultima_actualizacion))


#str(ar_positivos) 


#revisamos y esta todo ok.


# Ya descargamos y redujimos preliminarmente la base quedándonos 
# con los datos relevantes, ahora vamos a comprimirlos y descargarlos a 
# nuestra computadora. Para ello, vamos a usar fst, creo yo una de las 
# mejores librerías de R para gestionar (usando los multiples núcleos de 
# nuestro procesador) archivos pesados.

# descargamos el archivo a nuestro equipo.

write.fst(ar_positivos, "ar_positivos.fst")


#Podemos borrar el csv original de nuestra carpeta con este comando

unlink("Covid19Casos.csv")


# leamos el archivo... 

ar_positivos <- read.fst("ar_positivos.fst")


# y vamos probar que funciona

summary(ar_positivos)



