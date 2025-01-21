library(tidyverse)

consum <- read.csv("data/Consum_d_energia_el_ctrica_per_municipis_i_sectors_de_Catalunya_20241222.csv")

attr(consum, 'names') <- c('Any', 'Provincia', 'Comarca', 
                           'Codi_Municipi', 'Municipi',
                           'Codi_Sector', 'Descripcio_Sector',
                           'Consum_kWh', 'Observacions')

summary(consum)

consum |>
  mutate(Any=as.character(Any)) |>
  ggplot() +
  geom_bar(aes(x=Any))

ggplot(consum) +
  geom_bar(aes(y=Provincia))

ggplot(consum) +
  geom_bar(aes(y=Comarca, fill=Provincia))

consum |>
  select(Codi_Municipi, Municipi) |>
  mutate(
    Codi_Municipi = str_pad(Codi_Municipi, width = 5, pad = '0')
  ) |>
  count(Codi_Municipi, Municipi) |>
  arrange(desc(n)) |>
  ggplot() +
  geom_histogram(aes(x=n / 10)) +
  labs(
    title = 'Sectores consumidores de energia eléctrica en Cataluña en la última década',
    y = 'Municipios',
    x = 'Sectores presentes en una década',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )

sectores <-
  consum |>
  select(Codi_Sector, Descripcio_Sector) |>
  mutate(
    Codi_Sector = as.character(Codi_Sector)
  ) |>
  count(Codi_Sector, Descripcio_Sector) 

municipios <- length(unique(consum$Municipi))
municipios

sectores |> 
  mutate (
    Sector = str_c(Codi_Sector, Descripcio_Sector, sep='-'),
    Obs_municipi = n / municipios
  ) |>
  select(Sector, Obs_municipi) |>
  mutate(
    Sector = fct_reorder(Sector, Obs_municipi, .desc=TRUE)) |>
  ggplot(aes(y=Sector, x=Obs_municipi)) +
  geom_col() +
  labs(
    title = 'Sectores consumidores de energia eléctrica en Cataluña en la última década',
    x = 'Sectores presentes en una década',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )

ggplot(consum, aes(y=Consum_kWh))+
  geom_boxplot()

consum |>
  group_by(Any, Provincia, Descripcio_Sector) |>
  summarise(Consum_MWh = sum(Consum_kWh / 1000 / 365, na.rm=TRUE)) |>
  ggplot(aes(x=Consum_MWh))+ 
  geom_violin(aes(y=Provincia)) +
  labs(
    title = 'Perfil consumo anual por provincia',
    x = 'Consumo en MWh / dia',
    caption = 'Source: Institut Català d’Energia (ICAEN) '
  )

consum |>
  group_by(Any, Descripcio_Sector) |>
  summarise(Consum_MWh = sum(Consum_kWh / 1000 / 365, na.rm=TRUE)) |>
  ggplot(aes(x=Consum_MWh))+ 
  geom_violin(aes(y=Descripcio_Sector)) +
  labs(
    title = 'Perfil consumo anual por Sector',
    x = 'Consumo en MWh / dia',
    y = NULL,
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )
  
ggplot(consum) +
  geom_bar(aes(y=Observacions))

consum_diari <- consum |>
  mutate(
    Any = as.integer(Any),
    Codi_Municipi = str_pad(Codi_Municipi, width = 5, pad = '0'),
    Codi_Sector = as.character(Codi_Sector),
    MWh_dia = Consum_kWh / 1000 / 365
  ) |>
  select(!c('Consum_kWh','Observacions')) |>
  na.omit() 

consum_diari |>
  group_by(Any, Descripcio_Sector) |>
  summarise(MWh_dia = sum(MWh_dia)) |>
  ungroup() |>
  ggplot(aes(x=Any, y=MWh_dia, color=Descripcio_Sector)) +
  geom_line(linewidth=1.5) +
  scale_x_continuous(breaks = seq(2013, 2022, by = 1), 
                     limits=c(2013, 2022)) +
  scale_y_log10() +
  labs(
    title = 'Evolucion del consumo por sector',
    subtitle = 'Salvo el descenso marcado por el COVID-19 no se observa tendencia generalizada al mismo',
    x = 'Año',
    y = 'MWh / dia',
    color='Sector',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )

consum_diari |>
  group_by(Any, Descripcio_Sector) |>
  summarise(MWh_dia = sum(MWh_dia)) |>
  ungroup() |>
  ggplot(aes(x=Any, y=MWh_dia, color=Descripcio_Sector)) +
  geom_line(linewidth=1.5) +
  scale_x_continuous(breaks = seq(2013, 2022, by = 1), 
                     limits=c(2013, 2022)) +
  # scale_y_log10() +
  labs(
    title = 'Evolucion del consumo por sector',
    subtitle = 'Salvo el descenso marcado por el COVID-19 no se observa tendencia generalizada al mismo',
    x = 'Año',
    y = 'MWh / dia',
    color='Sector',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )


