#Download the COVID data
COVIDdata = read.csv("owid-covid-data.csv")
library(tidyverse)
library(drc)
WeeklyCOVIDdata = subset(COVIDdata, select = c(location,
                                               population, date, new_cases,
                                               new_deaths, people_fully_vaccinated,
                                               people_vaccinated)) #breaking up the data with the variables we want, we can change this
WeeklyCOVIDdata$date = as.Date(WeeklyCOVIDdata$date, format = "%Y-%m-%d")
#R doesn't read the dates right
WeeklyCOVIDdata = WeeklyCOVIDdata %>% mutate(week = format(date, format="%Y-%U"))
#making a weekly column to group the data by

special.max = function(x){ #Somehow I have to get the max function to ignore an NA when there are other values, but to value something as NA when no value is present
  ifelse( !all(is.na(x)), max(x, na.rm=T), NA)
}
WeeklyCOVIDdata = WeeklyCOVIDdata %>%
  group_by(location, week) %>% #groups the weekly data first by location, then by week
  summarise(new_cases_weekly=sum(new_cases), #getting weekly new cases
            pop_week = special.max(population), #why would I sum population
            ppl_fully_vacc_week = special.max(people_fully_vaccinated),
            ppl_vacc_week = special.max(people_vaccinated), #these aren't new
          ) #to allow for the columns to be the same length
#We can change the variables after this point to get the proportions and percentages Dr. Irazarry wanted, or select different columns initially

CleanWeekData = WeeklyCOVIDdata %>% #making the weekly data into the data we want with percentages and stuff
  mutate(new_cases_per_100k = new_cases_weekly/pop_week*100000, #weekly cases every 100,000 ppl
         percent_ppl_fully_vacc = (percent_ppl_fully_vacc-lag(percent_ppl_fully_vacc))/lag(percent_ppl_fully_vacc)*100, #percent ppl fully vaccinated
         percent_ppl_vacc = (percent_ppl_vacc-lag(percent_ppl_vacc))/lag(percent_ppl_vacc)*100
  ) #percent ppl vaccinated
CleanWeekData = subset(CleanWeekData, select = -c(new_cases_weekly, #dropping the unmodified columns
                                                  ppl_fully_vacc_week, ppl_vacc_week))

library(shiny)
#Run the new weekly data into a set of plots with two axis, one for percent, one for number per 100k people
ui = fluidPage(
  selectInput(inputId = "location",
              label = "Select a Country",
              choices = unique(CleanWeekData$location)), # list of non-duplicated countries
  plotOutput("line")
)


server = function(input, output){
  output$line = renderPlot( {
    ggplot(CleanWeekData %>%  
             filter(location == input$location)) +
      geom_point(mapping = aes(x = percent_ppl_fully_vacc, color = "People Fully Vaccinated [Weekly %]", y= new_cases_per_100k, color= "New Weekly Cases"), na.rm=TRUE) +
      geom_point(mapping = aes(x = percent_ppl_vacc, color = "People Vaccinated [Weekly %]", y = new_cases_per_100k, color='green'), na.rm=TRUE) +
      xlab("Vaccinations") + ylab("Count Per 100,000 [triangle]") +
      ggtitle("COVID-19 Pandemic") +
      labs(color = "") + theme_bw()
  }
  )
}







# Run the application
shinyApp(ui = ui, server = server)