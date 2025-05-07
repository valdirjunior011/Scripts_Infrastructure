#### Import Libraries
import csv
import re
import requests
from bs4 import BeautifulSoup
import time
import requests
import urllib3

#### Disable Warning SSL 
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
requests.packages.urllib3.disable_warnings()

#### Creating CSV
filename = 'jobs.csv'
f = csv.writer(open(filename, 'w', newline='', encoding="utf-8"))
f.writerow(['Job Name', 'Job Link'])

#### Searching Keywords
#### JobTitle put %20 ex. 'Devops'+'%20'+'Engineer'
#### Place = County or City
JobTitle = ''
place = ''

#### 25 jobs for Page 
#### Changing ( 25, 50, 75, etc )
amountOfPagesSearch = 25

joblist = []

print("# Collecting job links")

for page in range(24, amountOfPagesSearch, 25):
    print('Page: ' + str(page))
    html = requests.get('https://www.linkedin.com/jobs/search/?keywords=' + JobTitle + '&location=' + place + '&start=' + str(page), verify= False)
    soup = BeautifulSoup(html.text, 'html.parser')
    joblist = joblist + soup.find(class_='jobs-search__results-list').findAll('a', { 'class' : 'base-card__full-link' })
print("# Filtering jobs")

#### Save the results on CSV
#### Title and Link 
filteredJobs = []

for job in joblist:
    link = job.get('href', '#')
    name = job.find('span').text.strip()
    print('Found:', [name])
    f.writerow([name, link])