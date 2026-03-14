# California Housing Dashboard

An interactive dashboard for exploring the geographic and socioeconomic drivers of housing prices in California (1990).

**Live dashboards**
- **Preview:** https://019cede5-d232-35f4-8ac0-ec6e0de96888.share.connect.posit.cloud/


## Why this dashboard exists (for users)

Housing prices vary dramatically across California due to geography, income levels, housing characteristics, and proximity to amenities such as the ocean. This dashboard enables **user-driven exploration** of these relationships using California housing data from 1990.

It is designed to help users:
- visually investigate spatial patterns in house prices
- understand how socioeconomic and structural factors relate to price variation
- identify clusters of high- and low-value regions without writing code

The project also serves as a **proof of concept** for building extensible housing dashboards that could be adapted to more recent or broader datasets.

---

## What you can do with it

- Explore an **interactive map** of median house values by location
- Investigate relationships between house price and:
  - median household income
  - housing age
  - proximity to the ocean
- Compare housing characteristics using scatter plots and bar charts

---

## Run locally (for contributors)

### Clone the repository

Using HTTPS:
```bash
git clone https://github.com/mdskwong/DSCI-532_2026_5_california_housing_R.git
```

Or using SSH:
```bash
git clone git@github.com:mdskwong/DSCI-532_2026_5_california_housing_R.git
```

Navigate to the project root:
```bash
cd DSCI-532_2026_5_california_housing_R
```
Create the environment

```bash
Rscript -e "install.packages(c('shiny', 'bslib', 'tidyverse', 'leaflet', 'sf', 'scales', 'bsicons'))"
```

Launch the dashboard

```bash
Rscript -e "shiny::runApp('app.R', launch.browser = FALSE, port = 8000)"
```

Open http://127.0.0.1:8000 in your browser.

## Authors

- Teem KWONG

## Attribution

Generative AI tools (Google Gemini, OpenAI ChatGPT, and GitHub Copilot) were used to assist with code generation and documentation drafting. All generated content was reviewed and edited by the authors to ensure accuracy and quality.