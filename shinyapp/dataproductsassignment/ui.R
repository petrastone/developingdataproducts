#
# https://petrastone.shinyapps.io/religionireland/
#

library(shiny)
library(datakindr)
library(DT)
library(shinycssloaders)
library(leaflet)
library(forcats)
library(dplyr)
library(memoise)
library(reshape2)
library(plotly)
library(ggplot2)

shinyUI(fixedPage(
    tags$head(
        tags$style(HTML("
                        .selectize-dropdown { z-index: 9999!important; }
                        .modebar {display: none; }
                        "))
        ),
    title="Religion in Ireland 1891-2016 (Source CSO)",
    HTML("<h1>Religion in Ireland 1891-2016 <small>(Source CSO)</small></h1>"),
    HTML('<p>The <a href="https://www.cso.ie/en/" target="_blank">Central Statistics Office</a> (CSO) in the Republic of Ireland publishes records for Censuses of population carried out in Ireland via its <a href="https://www.cso.ie/webserviceclient/" target="_blank">StatBank API</a> as part of an <a href="https://en.wikipedia.org/wiki/Open_data" target="_blank">Open Data</a> initiative. This <a href="https://www.cso.ie/webserviceclient/DatasetDetails.aspx?id=EY037" target="_blank">dataset (EY037)</a> describes religious demographics from 1891 to 2016 for most of the Island of Ireland (the 26 counties of Republic of Ireland). <a href="http://www.census.nationalarchives.ie/help/history.html" target="_blank">Censuses</a> were carried out roughly every 10 years up to 1946 and roughly every 5 years since then. Census records for 1951, 1956, 1966, 1979, 1986 and 1996 are missing from this particular dataset.</p>'),
    wellPanel(
        fluidRow(
            column(7,
                   radioButtons('metric',
                                'Statistic',
                                choices=c(
                                    '% of Population'='PercTotal',
                                    'Total Population'='Total',
                                    '% Change Total'='PercChangeTotal',
                                    '% Change as % of Population'='PercChange'
                                ),
                                inline=T
                   ) 
            ),
            column(5,
                   selectInput(
                       'religion',
                       'Religion',
                       choices=c(
                           'Choose'='',
                           'Roman Catholic',
                           'Church of Ireland (incl. Protestant)',
                           'Presbyterian',
                           'Methodist, Wesleyan',
                           'Jewish',
                           'Other stated religion (nec)',
                           'No religion',
                           'Not stated'
                       ),
                       multiple = T
                   )
                
            )
            
        )
    ),
    fluidRow(
        column(12,
               withSpinner(plotlyOutput('timeline2'), type=8, color.background='#FFFFFF'),
               hr(),
               withSpinner(plotlyOutput('timeline'), type=8, color.background='#FFFFFF')
        )
    ),
    fluidRow(
        column(12,
               hr(),
               withSpinner(DTOutput('results'), type=8, color.background='#FFFFFF')
        )
        
    )
  )
)

