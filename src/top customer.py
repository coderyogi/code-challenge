import re
import pandas as pd
import numpy as np
import ast
from datetime import date, timedelta
from dateutil import rrule
import sys

def TopXSimpleLTVCustomers(x, ddf):
  
  '''Return the top x customers with the highest Simple Lifetime Value from data.
  
    Keyword arguments:
    x -- represents the number of top customers to be returned.
    ddf -- dataframe representing the data to use to calculate the LTV
    
    Returns: a dataframe with the top x customers based on Simple Lifetime Values
    
  '''
  
  #average lifespan for a Shutterfly customer is 10years
  lifespan = 10
  
  #Transform following
  #Populate customer_id for all new customers with the key as their customer_id
  #Replace all NaN with 0 for total_amount
  #Based on current data  remove all alphabets indicating currencies "USD"
  #Convert string representation of events_time to date
  
  ddf['customer_id'] = ddf['customer_id'].fillna(ddf['key'])
  ddf['total_amount'] = ddf['total_amount'].fillna(0)
  ddf['total_amount'] = ddf['total_amount'].replace(r'[A-Za-z]','', regex=True).astype(float)
  ddf['event_time'] = ddf['event_time'].astype('datetime64[ns]')
  #print(mdf)
  
  #Get the total amount spent by ORDER type
  rdf = pd.DataFrame(ddf[ddf.type == 'ORDER'].groupby('customer_id')['total_amount'].sum())
  #print(rdf)
  
  #Calculate the number of weeks in the data provided
  numofweeks = weeks_between(min(ddf.event_time), max(ddf.event_time))
  
  #Calculate the Average value based on the total spent over the number of weeks included in the data
  sdf = pd.DataFrame(rdf.groupby('customer_id')['total_amount'].sum()*lifespan/numofweeks)
  
  #Sort the above and return the top x customers requested
  return(sdf.sort_values('total_amount', ascending=False)[0:x])
     
def initialize_events(filename):
  '''Initialize the events data from a particular file
  
    Keyword arguments:
    filename -- the name of the file containing the data
      
    Returns: a dictionary of the events data
    
  '''
  try:
    with open(filename, "r") as data:
      return(ast.literal_eval(data.read()))
  except IOError:
    print('File not found')
    sys.exit()
 
  
def ingest(event):
  '''Used to ingest new data as they get collected
  
    Keyword arguments:
    event -- string representation of the new data
      
    Returns: a dictionary of the events
    
  '''
  #sample event = {"type": "ORDER", "verb": "NEW", "key": "68d84e5d1a90", "event_time": "2017-01-12T12:55:55.555Z", "customer_id": "96f55c7d8f43", "total_amount": "182.44 USD"}
  return(ast.literal_eval(event))

def weeks_between(start_date, end_date):
  '''Calculates the number of weeks between start and end
  
    Keyword arguments:
    start_date -- begining period
    end_date -- ending period
      
    Returns: the number of weeks between start and end date
  '''
  
  weeks = rrule.rrule(rrule.WEEKLY, dtstart=start_date, until=end_date)
  return weeks.count()

  
if __name__ == "__main__":
  
  topcustomers = 3;
  events = 'events.txt'
  
  dictionary = initialize_events(events)
  df = pd.DataFrame(dictionary)
  print('Total Records in data set is', len(df))
    
  print(TopXSimpleLTVCustomers(topcustomers,df))
  
  event = '{"type": "ORDER", "verb": "NEW", "key": "68d84e5d1a90", "event_time": "2018-01-11T12:55:55.555Z", "customer_id": "96f55c7d8f48", "total_amount": "932.34 USD"}'
  dictionary = ingest(event)
  df = df.append(dictionary, ignore_index=True)
  
  print('Total Records in data set is', len(df))
  print(TopXSimpleLTVCustomers(topcustomers,df))

  event = '[{"type": "ORDER", "verb": "NEW", "key": "68d84e5d1a91", "event_time": "2018-01-11T12:55:55.555Z", "customer_id": "96f55c7d8f45", "total_amount": "332.4 USD"},{"type": "ORDER", "verb": "NEW", "key": "68d84e5d1a92", "event_time": "2018-01-11T12:55:55.555Z", "customer_id": "96f55c7d8f45", "total_amount": "712.34 USD"}]'
  #dictionary = ingest(event)
  #df = df.append(dictionary, ignore_index=True)
  
  #print('Total Records in data set is', len(df))
  #print(TopXSimpleLTVCustomers(topcustomers,df))



