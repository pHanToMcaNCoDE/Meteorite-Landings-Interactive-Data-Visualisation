#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(psych)
library(ggplot2)
library(dplyr)
library(VIM)
library(tidyverse)

# Did not work
#install.packages("summarytools", dependencies = TRUE)
#library(summarytools)


# Reference: https://www.r-bloggers.com/2024/10/top-10-r-packages-for-exploratory-data-analysis-eda-bookmark-this/
install.packages("skimr")
library(skimr)



library(leaflet)
library(sf)

install.packages(c("rnaturalearth", "rnaturalearthdata"))
library(rnaturalearth)
library(rnaturalearthdata)


# Reference: https://docs.ropensci.org/rnaturalearthhires/

install.packages(
  "rnaturalearthhires",
  repos = "https://ropensci.r-universe.dev",
  type = "source"
)

library(rnaturalearthhires)





df <- read.csv("Meteorite Landings.csv")

# 45,716 rows, 10 columns
#dim(df)
skim(df)


View(df)


# Strong skewness on mass, reclat, and reclong variables.
# Valid meteor name is 99.8% - 45641 and relict names are .2% - 75 of them
summary(df)
describe(df)


# Converting all character columns to factors. lapply returns a list, whihc is good for a 
# dataframe

df <- data.frame(lapply(df, function(x) {
  if (is.character(x)) as.factor(x)
  else x
}))

# Columns mass.g., year, reclat, reclong have missing values.
# reclat and reclong has 7315 missing values, year has 291 missing values, 
# and mass has 131 missing values

colSums(is.na(df))


# Total missing values - 15,052
sum(is.na(df))


# There are missing values in mass, latitude, longitude variables
a <- aggr(df)
a

# save proportion of missingness plot
quartz.save("proportion_of_missingness.png")


par(mfrow=c(1,1))

# Lat
yr_v_lat <- df[, c("year","reclat")]

# Missing latitude values from recent years (1981-2010) - MAR
barMiss(yr_v_lat)
quartz.save("missing_data_in_reclat.png")

marginplot(yr_v_lat)

# Long
yr_v_lon <- df[, c("year","reclong")]

# Missing longitude values from recent years (1997-2010)
barMiss(yr_v_lon)

# save barMiss plot
quartz.save("missing_data_in_reclong.png")

marginplot(yr_v_lon)




# For handling dataset, We 
# omit them during visualisation because it is does not make sense
# to use imputation on latitude and longitude dataset. We do not know the exact
# co-ordinates where they landed


df %>% 
  filter(is.na(reclat)) %>% 
  select(GeoLocation) %>% 
  head(10) %>% 
  pull(GeoLocation)

table(df$nametype)
table(df$fall)

# World and USA maps loaded once at startup (not inside server)
world <- ne_countries(scale = "large", returnclass = "sf")
usa <- ne_states(returnclass = "sf", country = "United States of America")

# Filtering out Alaska and Hawaii because they are far away from most states of the usa and it will make
# the map small

usa_filter <- usa %>% filter(!name %in% c("Alaska", "Hawaii")) 


# Top 10 meteorite classes
recent_met <- df %>%
  filter(!is.na(year)) %>%
  count(recclass) %>%
  arrange(desc(n)) %>%
  head(10)


# UI block

ui <- fluidPage(
  titlePanel("Meteorite Landings Dashboard"),
  
  tabsetPanel(
    
    # Tab 1: Global Map
    tabPanel("Global Map",
             sidebarLayout(
               sidebarPanel(
                 radioButtons("fall_filter", "Discovery Type:",
                              choices = c("All", "Fell", "Found"),
                              selected = "All"),
                 sliderInput("year_range", "Year Range:",
                             min = 1900, max = 2024,
                             value = c(1900, 2024), sep = "")
               ),
               mainPanel(plotOutput("global_map", height = "500px"))
             )
    ),
    
    # Tab 2: USA Map
    tabPanel("USA Map",
             mainPanel(plotOutput("usa_map", height = "500px"))
    ),
    
    # Tab 3: Discoveries Over Time
    tabPanel("Discoveries Over Time",
             mainPanel(plotOutput("line_chart", height = "500px"))
    ),
    
    # Tab 4: Mass Distribution
    tabPanel("Mass Distribution",
             mainPanel(plotOutput("density_plot", height = "500px"))
    ),
    
    # Tab 5: Discovery Type
    tabPanel("Discovery Type",
             mainPanel(plotOutput("bar_chart", height = "500px"))
    ),
    
    # Tab 6: Meteorite Classes
    tabPanel("Meteorite Classes",
             mainPanel(plotOutput("col_chart", height = "500px"))
    )
    
  )
)


# Server Block
server <- function(input, output) {
  
  # Reactive filtered data for global map
  filtered_data <- reactive({
    data <- df %>%
      filter(!is.na(reclat) & !is.na(reclong),
             year >= input$year_range[1],
             year <= input$year_range[2])
    
    if (input$fall_filter != "All") {
      data <- data %>% filter(fall == input$fall_filter)
    }
    data
  })
  
  # 1.) Meteorites found since 2000
  
  output$global_map <- renderPlot({
    ggplot(data = world) +
      geom_sf() +
      geom_point(data = filtered_data(),
                 aes(x = reclong, y = reclat,
                     size = log10(mass..g.),
                     color = fall),
                 alpha = 0.3) +
      labs(
        x = "Longitude",
        y = "Latitude",
        title = "Global Meteorite Landings by Discovery Type",
        color = "Discovery Type",
        size = "Mass (log10 grams)"
      )
  })
  
  # 2.) Distribution of discovery type
  output$usa_map <- renderPlot({
    po <- df %>%
      filter(!is.na(reclat) & !is.na(reclong),
             mass..g. > 0, year >= 2000) %>%
      st_as_sf(coords = c("reclong", "reclat"), crs = st_crs(4326))
    
    usa_points <- st_filter(po, usa_filter)
    
    # Add text to map: https://r-spatial.org/r/2018/10/25/ggplot2-sf-2.html#:~:text=States%20(polygon%20data),where%20to%20draw%20their%20names.
    
    ggplot(data = usa_filter) +
      geom_sf() +
      geom_sf(data = usa_points,
              aes(size = log10(mass..g.), color = fall),
              alpha = 0.3) +
      geom_sf_text(data = usa_filter, aes(label = name), size = 3) +
      labs(
        x = "Longitude",
        y = "Latitude",
        title = "Meteorite Landings in The United States Of America by Discovery Type",
        color = "Discovery Type",
        size = "Mass (log10 grams)"
      )
  })
  
  # 3.) Bubble Map showing where meteors fell
  
  
  # Reference: https://r-spatial.org/r/2018/10/25/ggplot2-sf.html
  output$line_chart <- renderPlot({
    df %>%
      group_by(year) %>%
      filter(year >= 1900 & year <= 2024) %>%
      count(fall) %>%
      ggplot(aes(x = year, y = n, color = fall)) +
      geom_line() +
      geom_point(size = 0.8) +
      labs(
        x = "Year",
        y = "Number of Meteorite Discoveries",
        title = "Discoveries per year, Fell vs Found",
        color = "Discovery Type"
      )
  })
  
  # 4.) Specific Bubble Map (USA) - Where
  
  
  # Reference: https://www.rdocumentation.org/packages/sf/versions/1.0-23/topics/st_as_sf
  output$density_plot <- renderPlot({
    df %>%
      filter(mass..g. > 0, !is.na(mass..g.)) %>%
      ggplot(aes(x = log10(mass..g.), fill = fall)) +
      geom_density(alpha = 0.8) +
      labs(
        x = "Mass (log10 grams)",
        title = "Distribution of Meteorite Mass By Discovery Type",
        fill = "Discovery Type"
      )
  })
  
  # 5.) Density Plot - Distribution of meteorite mass by discovert type
  output$bar_chart <- renderPlot({
    df %>%
      ggplot(aes(x = fall, fill = fall)) +
      geom_bar() +
      labs(
        x = "Discovery Type",
        y = "Count",
        title = "Distribution of Discovery Type",
        fill = "Discovery Type"
      )
  })
  
  # 6.) Line plot - Discoveries per year as a line, split by Fell vs Found.
  
  
  # Fell: Witnessed meteorites have roughly been the same over time.
  # Found: Fluctuates over time. Spiked around 1980 and dropped after 2010.
  
  output$col_chart <- renderPlot({
    df %>%
      filter(year > 2000, !is.na(year), recclass %in% recent_met$recclass) %>%
      count(year, recclass) %>%
      ggplot(aes(x = year, y = n, fill = recclass)) +
      labs(
        title = "Top 10 Meteorite Classes Found Since 2000",
        x = "Year",
        y = "Number of Meteorites"
      ) +
      geom_col()
  })
  
}


shinyApp(ui, server)
