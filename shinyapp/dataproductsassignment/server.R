#
# https://petrastone.shinyapps.io/religionireland/
#

shinyServer(function(input, output, session) {
    
    get_cso_data <- function(cso_dataset_code='EY037'){
        cso_base_url <-
            "https://www.cso.ie/StatbankServices/StatbankServices.svc/jsonservice/responseinstance/"
        
        allData <- rjstat::fromJSONstat( readLines(paste0(cso_base_url, 'EY037')),use_factors=T )[[1]]
        
        data2 <- allData %>%
            filter(`County`=='State', 
                   Religion!='All religions',
                   Statistic=='Population (Number)'
                   ) %>%
            select(-Statistic, -`County`, Total=value) %>%
            droplevels() 
        
        totals <- data2 %>%
            group_by(`Census Year`, Religion) %>%
            summarise(Total=sum(Total))
        
        finalData <- data2 %>%
            group_by(`Census Year`) %>%
            summarise(TotalPop=sum(Total)) %>%
            inner_join(totals, by=c('Census Year')) %>%
            mutate(PercTotal=Total/TotalPop) %>%
            select(-TotalPop ) %>%
            group_by(Religion) %>%
            arrange(Religion, `Census Year`) %>%
            mutate(Lag=lag(Total),
                   PercChangeTotal = (Total-lag(Total))/lag(Total),
                   PercChange = (PercTotal-lag(PercTotal))/lag(PercTotal)
                   ) %>%
        ungroup() %>%
        arrange(desc(`Census Year`), Religion)
        
        finalData$PercChangeTotal <- ifelse( is.nan(finalData$PercChangeTotal) | is.infinite(finalData$PercChangeTotal) | is.na(finalData$PercChangeTotal),
                                       0,
                                       finalData$PercChangeTotal
         )
        
        finalData$PercChange <- ifelse( is.nan(finalData$PercChange) | is.infinite(finalData$PercChange) | is.na(finalData$PercChange),
                                             0,
                                             finalData$PercChange
        )
        
        finalData$Lag <- NULL
        finalData$`Census Year` <- as.integer(as.character(finalData$`Census Year` ))
        
        #browser()
        
        print( str(finalData))
        
        return(finalData %>% droplevels())

    }
    
    cacheData <- memoise(get_cso_data)
    
    myPal <- c(
        'Roman Catholic' ='MediumSeaGreen',
        'Church of Ireland (incl. Protestant)' ='CornflowerBlue',
        'Presbyterian' ='DeepSkyBlue',
        'Methodist, Wesleyan' ='DodgerBlue',
        'Jewish' ='purple',
        'Other stated religion (nec)' ='orange',
        'No religion' ='darkGray',
        'Not stated'='black'
    )
    
    
    censi <- data.frame( 'CensusYear'=c(
        1891,
        1901,
        1911,
        1926, 
        1936, 
        1946, 
        1951, 
        1956, 
        1961, 
        1966, 
        1971, 
        1979, 
        1981, 
        1986, 
        1991, 
        1996, 
        2002,
        2006,
        2011,
        2016
    ),
    'Authority'=c(
        'Registrar General of Births, Deaths and Marriages',
        'Registrar General of Births, Deaths and Marriages',
        'Registrar General of Births, Deaths and Marriages',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office',
        'Central Statistics Office'
    )
    )
    
    doGraph <- function(graphType='bubble') {
        
        metric <- input$metric
        religion <- input$religion
        
        if( is.null(religion)) {
            data <- cacheData()
        } else {
            data <- cacheData() %>%
                filter(Religion %in% religion)
        }
        
        missingData <- censi %>%
            filter(!`CensusYear` %in% data$`Census Year`)
        
        presentData <- censi %>%
            filter(`CensusYear` %in% data$`Census Year`)
        
        #browser()
        if(metric=='Total') {
            myScaleFunc <- scales::comma
        } else {
            myScaleFunc <- scales::percent
        }
        
        if(metric=='PercChangeTotal' | metric=='PercChange' ) {
            myScaleFunc <- function(x) { 
                sprintf("%+.2f%%", x*100 )
            }
            barPosition <- position_dodge2(width = 16, padding = 0)
        } else {
            barPosition <- 'stack'
        }
        
        if(graphType=='bubble') {
            # https://plotly-book.cpsievert.me/key-frame-animations.html
            myAes <- aes(
                x=`Census Year`,
                y=get(metric),
                color=Religion,
                text=paste0(
                    Religion, '<br>',
                    `Census Year`, ' Census<br>',
                    myScaleFunc(get(metric))
                ),
                alpha=.7
            )
            
            myGeom <- geom_jitter( aes(size = get(metric), frame = `Census Year`, ids = Religion) ) 
            myColScale <- scale_color_manual(name = "Something",values = myPal, guide=FALSE) 
            myLine <- geom_vline(xintercept=1961, size=.1, color="gray") 
            myXScale <- scale_x_continuous(breaks=unique(data$`Census Year`)) 
            
        } else {
            # Bar
            data$`Census Year` <- factor(data$`Census Year`)
            myAes <- aes(
                x=`Census Year`,
                y=get(metric),
                fill=Religion,
                text=paste0(
                    Religion, '<br>',
                    `Census Year`, ' Census<br>',
                    myScaleFunc(get(metric))
                ),
                alpha=.7
            )
            
            myGeom <- geom_bar(stat='identity', position=barPosition )
            myColScale <- scale_fill_manual(name = "Something",values = myPal, guide=FALSE) 
            myLine <- NULL
            myNote <- NULL
            myXScale <- NULL
        }
        
        p <- ggplot(
            data,
            mapping <- myAes
        ) 
        p <- p +  
            geom_hline(yintercept=0, size=.1, colour='gray') +
            myGeom +
            myColScale +
            scale_y_continuous(labels=myScaleFunc) +
            myXScale +
            geom_vline(data=presentData, aes(xintercept=CensusYear, text=paste0(CensusYear, ' ', Authority) ), size=.1, color="gray", linetype="dotted"  )  +
            geom_vline(data=missingData, aes(xintercept=`CensusYear`, text=paste0(CensusYear, ' ', Authority)), size=.1, color="red", linetype="dotted"  )  +
            theme_classic() +
            ylab(metric) + xlab('') +
            theme(legend.title=element_blank(), 
                  axis.text.x = element_text(angle=45) )
        
        p <- ggplotly(p, tooltip = c('text')) %>%
            layout(annotations = list(x = c("1926", "1961"), 
                                      y = 0, 
                                      text = c("1st Free State Census 1926", "1961 Census"), 
                                      showarrow = F, 
                                      textangle=-90, 
                                      yshift=c(75, 50),
                                      align = 'left',
                                      font = list(
                                        family = "Droid Sans",
                                        color = "lightGray",
                                        size = 12
                                      )
                )
            )
    }
    
    output$timeline <- renderPlotly({
        doGraph(graphType='bubble')
    })
    
    output$timeline2 <- renderPlotly({
        doGraph(graphType='bar')
    })
    
    output$results <- renderDT({
        religion <- input$religion
        
        if( is.null(religion) ) {
            data <- cacheData()
        } else {
            data <- cacheData() %>%
                filter(Religion %in% religion)
        }
        
        dt <- DT::datatable( data, rownames = F ) %>%
            formatCurrency(
                columns=c('Total'),
                currency = "",
                digits=0
            ) %>%
            formatPercentage(
                columns=c('PercTotal','PercChangeTotal','PercChange')
            )
    })
}
)

