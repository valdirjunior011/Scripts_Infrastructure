import csv
import re
import requests
from bs4 import BeautifulSoup
import time
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
requests.packages.urllib3.disable_warnings()

filename = 'jobs.csv'
f = csv.writer(open(filename, 'w', newline=''))

f.writerow(['Job Name', 'Job Link'])

jobName = 'Devops' + '%20' + 'engineer'
place = 'Germany'
amountOfJobs = 100
joblist = []

print("# Collecting first n job links")

for page in range(25, amountOfJobs, 25):
    print('Page: ' + str(page))
    html = requests.get('https://www.linkedin.com/jobs/search/?keywords=' + jobName + '&location=' + place + '&start=' + str(page), verify= False)
    soup = BeautifulSoup(html.text, 'html.parser')
    joblist = joblist + soup.find(class_='jobs-search__results-list').findAll('a', { 'class' : 'base-card__full-link' })
print("# Filtering jobs")

filteredJobs = []

for job in joblist:
    link = job.get('href', '#')
    name = job.find('span').text

    jobHtml = requests.get(str(link), verify=False)
    jobSoup = BeautifulSoup(jobHtml.text, 'html.parser')
    
    description = jobSoup.find(class_='show-more-less-html__markup')
    found = description.findAll(string=re.compile(r"\bKubernetes\b",re.I))
    if found:
        print('Found:', str(name))
        f.writerow([name, link])