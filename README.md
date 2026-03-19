# Meteorite Landings — Interactive Data Visualisation

An interactive R Shiny dashboard exploring 45,716 meteorite landing records from NASA's Open Data Portal.

Built for Data9005 (Data Visualisation) as part of the MSc in Data Science & Analytics, MTU Cork, 2025/26.

---

## The Question

> Are meteorites actually falling more in populated areas — or are we just better at finding them there?

This project uses geospatial mapping, missing data analysis, and time-series visualisation to answer that, and a few other questions buried in the data.

---

## Repository Structure

```
Meteorite-Landings-Interactive-Data-Visualisation/
│
├── dataset/          # NASA meteorite landings CSV (source: NASA Open Data Portal)
├── report/           # Written report (PDF) submitted for Data9005
├── shiny_app/        # app.R — the full Shiny dashboard code
└── visualisations/   # Exported plots (PNG) generated during analysis
```

---

## Dashboard Overview

The Shiny app has six tabs:

| Tab | What it shows |
|---|---|
| **Global Map** | Geospatial bubble map of all landings, filterable by discovery type and year range |
| **USA Map** | Zoomed-in view clipped to the contiguous US using `sf` spatial filtering |
| **Discoveries Over Time** | Line chart of annual discoveries split by Fell vs Found |
| **Mass Distribution** | Density plot comparing meteorite mass by discovery type (log10 scale) |
| **Discovery Type** | Bar chart of Fell vs Found counts across the full dataset |
| **Meteorite Classes** | Stacked column chart of the top 10 classes recorded since 2000 |

---

## Key Findings

**Where meteorites land vs where they're found are different questions.**
The maps cluster heavily around California, Arizona, and other populated regions — but 97.6% of all records are meteorites that were *found*, not witnessed. Population density doesn't attract meteorites; it just means more people around to find them.

**The discovery spike in the 1980s has a specific cause.**
Discoveries were flat for decades, then surged from the late 1970s onward. That traces directly to the ANSMET programme (Antarctic Search for Meteorites), funded from 1976–77, which has recovered over 20,000 meteorites since. The witnessed category barely moved across the same period.

**Witnessed meteorites tend to be heavier.**
The density plot shows a clear rightward shift in mass for witnessed meteorites. Larger impacts produce sound, light, and vibration — they're harder to miss.

---

## Missing Data

The `reclat` and `reclong` columns had **7,315 missing values (~16%)**.

Visualising the missingness with the VIM package showed it clustered between 1981–2010 — consistent with **Missing At Random (MAR)**, not MCAR. Dropping these rows entirely would have introduced bias into visualisations that didn't need coordinates at all. Instead, missing values were filtered only within the plots that required geolocation data.

---

## Running the App

1. Clone this repository
2. Open `shiny_app/app.R` in RStudio
3. Install dependencies:

```r
install.packages(c(
  "shiny", "ggplot2", "dplyr", "tidyverse",
  "sf", "rnaturalearth", "rnaturalearthdata",
  "VIM", "psych", "skimr", "leaflet"
))

install.packages(
  "rnaturalearthhires",
  repos = "https://ropensci.r-universe.dev",
  type = "source"
)
```

4. Make sure the meteorite CSV is present in the `dataset/` folder
5. Click **Run App** in RStudio

---

## Tech Stack

| Tool | Purpose |
|---|---|
| R + Shiny | Dashboard framework and interactivity |
| ggplot2 | All visualisations |
| dplyr / tidyverse | Data wrangling |
| sf | Spatial operations and US border clipping |
| rnaturalearth | World and US state map polygons |
| VIM | Missing data visualisation |
| psych / skimr | Descriptive statistics |

---

## Data Source

NASA Open Data Portal — Meteorite Landings  
https://data.nasa.gov/dataset/meteorite-landings/resource/cca1a1f1-0039-44b1-a59b-9e2a9a5ca0c7

---

## Design Approach

Visualisation decisions were guided by Edward Tufte's five principles: comparison, causality, multivariate display, plurality of evidence, and credibility through documentation.
